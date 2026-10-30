# -*- coding: utf-8 -*-
"""
Local-only overrides for the offline reference copy of the retired WWU site.

Imported from urls_docker.py, i.e. after admin.autodiscover() has run, so every
ModelAdmin is already registered and can be adjusted in place. Nothing here is
imported by the production app: the legacy code under species/ is left exactly
as the server ran it, so it stays usable as evidence of what the old site did.

Two jobs:

1. Lock the admin read-only. Edits made against this copy would go nowhere --
   the live catalogue is the static site, not this database -- and an admin that
   accepts a change it then discards is worse than one that refuses it.

2. Add an "Export ALL Records as CSV" action. The legacy
   export_records_as_csv_action filters the selection with
   speciesimage__isnull=True, so it omits every record that has a photograph
   attached, and export_labels_as_csv_action omits every record that does not.
   Neither exports the whole selection, and nothing on screen says so.
"""
import csv

from django.contrib import admin
from django.http import HttpResponse


# Action callables whose names may be POSTed to a changelist. Everything else
# that writes is refused by ReadOnlyGuard in settings.py.
ALLOWED_ADMIN_ACTIONS = (
    'export_records_as_csv',
    'export_labels_as_csv',
    'export_all_records_as_csv',
)


def export_all_records_as_csv(modeladmin, request, queryset):
    """Every selected record, photographed or not, one row each."""
    opts = modeladmin.model._meta
    field_names = [f.name for f in opts.fields if f.name != 'csv_file']

    response = HttpResponse(mimetype='text/csv')
    response['Content-Disposition'] = (
        'attachment; filename=%s_all.csv' % unicode(opts).replace('.', '_')
    )
    writer = csv.writer(response)
    writer.writerow(field_names)

    for obj in queryset:
        row = []
        for name in field_names:
            value = getattr(obj, name, None)
            row.append(u'' if value is None else unicode(value).encode('utf-8', 'replace'))
        writer.writerow(row)

    return response


export_all_records_as_csv.short_description = 'Export ALL Records as CSV (including photographed)'


def _concrete_field_names(model):
    """Editable non-key fields -- the ones a change form would offer."""
    return [f.name for f in model._meta.fields if f.editable and not f.primary_key]


def _deny(self, request, obj=None):
    return False


def apply_read_only():
    """Make every registered admin look and behave as read-only."""
    # delete_selected is a *site-wide* action in Django 1.3 and is not filtered
    # by has_delete_permission the way later versions filter it, so hiding it
    # means removing it from the site rather than from each ModelAdmin.
    try:
        admin.site.disable_action('delete_selected')
    except KeyError:
        pass

    for model, model_admin in admin.site._registry.items():
        cls = model_admin.__class__
        # Patch the class so permission checks made on fresh instances (inline
        # formsets, popups) answer the same way.
        cls.has_add_permission = lambda self, request: False
        cls.has_delete_permission = _deny

        readonly = _concrete_field_names(model)
        cls.readonly_fields = readonly
        model_admin.readonly_fields = readonly
        model_admin.save_on_top = False
        model_admin.save_as = False

        for inline in getattr(model_admin, 'inlines', ()) or ():
            inline.max_num = 0
            inline.can_delete = False
            inline.extra = 0


def add_record_export_action():
    """Append the unfiltered export to whichever admin manages SpeciesRecord."""
    for model, model_admin in admin.site._registry.items():
        if model.__name__ != 'SpeciesRecord':
            continue
        actions = list(model_admin.actions or [])
        if export_all_records_as_csv not in actions:
            actions.append(export_all_records_as_csv)
        # Django 1.3's get_actions walks self.__class__.mro() and reads the
        # *class* attribute; an instance attribute is ignored entirely. Setting
        # only the instance here looks right, changes nothing, and says nothing.
        model_admin.__class__.actions = actions
        model_admin.actions = actions


def apply():
    # Order matters only in that both walk the same registry; the export is
    # added after the read-only pass so it is not mistaken for an editable field.
    apply_read_only()
    add_record_export_action()
    import sys
    names = sorted(m.__name__ for m in admin.site._registry)
    sr = [ma for m, ma in admin.site._registry.items() if m.__name__ == 'SpeciesRecord']
    sys.stderr.write('[local_overrides] site=%r registry=%d models=%s\n'
                     % (admin.site, len(names), ','.join(names)))
    sys.stderr.write('[local_overrides] SpeciesRecord admins=%d actions=%r\n'
                     % (len(sr), [getattr(a, '__name__', a) for a in (sr[0].actions or [])] if sr else None))
