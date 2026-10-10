# -*- coding: utf-8 -*-
"""
Docker-specific Django settings for local development.
Imports everything from settings_global, then overrides for a
self-contained Docker environment with MySQL.
"""
from settings_global import *

DEBUG = True
TEMPLATE_DEBUG = DEBUG

# MySQL database — matches the db service in docker-compose.yml
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('DB_NAME', 'pnwmoths'),
        'USER': os.environ.get('DB_USER', 'pnwmoths'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'pnwmoths'),
        'HOST': os.environ.get('DB_HOST', 'db'),
        'PORT': os.environ.get('DB_PORT', '3306'),
    }
}

SECRET_KEY = 'docker-local-dev-key-do-not-use-in-production'

# Site identity (moths)
SPECIES_SINGULAR = "moth"
SPECIES_PLURAL = "moths"
TEMPLATE_VARIABLES = {
    "SPECIES_SINGULAR": SPECIES_SINGULAR,
    "SPECIES_PLURAL": SPECIES_PLURAL,
    "GOOGLE_SEARCH": False,
    "ANALYTICS_ID": "",
    "FUSION_ID": "",
}

# Local memory cache (no memcached needed)
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.locmem.LocMemCache',
        'LOCATION': 'pnwmoths-dev',
    }
}

# Static and media files served by Django dev server
MEDIA_ROOT = os.path.join(PROJECT_ROOT, 'static', 'media/')
MEDIA_URL = '/media/'
STATIC_ROOT = os.path.join(PROJECT_ROOT, 'static', 'media', 'static/')
STATIC_URL = '/media/static/'

# Remove apps that aren't pip-installable in Docker
INSTALLED_APPS = tuple(
    app for app in INSTALLED_APPS
    if app not in (
        'csv_admin',
        'csvimporter',
        'admin_sentry',
        'django-lucid-key-report-generator',
    )
)

# Dummy search engine (no Xapian needed)
HAYSTACK_SEARCH_ENGINE = "dummy"

# Allow all hosts for local dev
ALLOWED_HOSTS = ['*']

# Exempt all URLs from login requirement for easier local browsing
LOGIN_EXEMPT_URLS = (r'.*',)

# Use database-backed sessions (works reliably with SQLite in Docker)
SESSION_ENGINE = "django.contrib.sessions.backends.db"

# Use Docker-specific URL conf that adds static file serving
ROOT_URLCONF = 'urls_docker'

# Remove cache and CSRF middleware for local dev
MIDDLEWARE_CLASSES = tuple(
    m for m in MIDDLEWARE_CLASSES
    if m not in (
        'django.middleware.cache.UpdateCacheMiddleware',
        'django.middleware.cache.FetchFromCacheMiddleware',
        'django.middleware.csrf.CsrfViewMiddleware',
    )
)

# Disable CSRF enforcement entirely for local dev (admin uses @csrf_protect
# decorator which also checks, so we need to set _dont_enforce_csrf_checks)
class DisableCsrfCheck(object):
    def process_view(self, request, callback, callback_args, callback_kwargs):
        request._dont_enforce_csrf_checks = True


class ReadOnlyGuard(object):
    """Refuse anything that would write to this copy.

    local_overrides.py hides the Add and Delete controls, but hiding a control
    is a cosmetic claim -- this is the one that holds, because it does not
    depend on every one of the twenty-odd registered admins having been patched
    correctly. Three kinds of POST are let through: the admin login form (which
    Django 1.3 posts back to whatever URL you asked for, flagged with
    this_is_the_login_form), the front-door sign-in at LOGIN_URL, and the CSV
    export actions, which are POSTs to a changelist that only read.
    """

    SAFE_METHODS = ('GET', 'HEAD', 'OPTIONS', 'TRACE')

    MESSAGE = (
        '<h1>This is a read-only copy</h1>'
        '<p>This is an offline reference copy of the retired PNW Moths site, kept '
        'for looking things up and for exporting records. It cannot be changed, '
        'because a change made here would not reach the live site &mdash; it would '
        'only sit in this copy on your own computer and be lost the next time the '
        'data was reloaded.</p>'
        '<p>Press the Back button in your browser to carry on.</p>'
    )

    def process_request(self, request):
        if request.method in self.SAFE_METHODS:
            return None
        # Signing in and out writes to the session table, not to the catalogue.
        # The legacy homepage is flagged login-required, so blocking this would
        # lock the front door of the copy we are shipping.
        if request.path_info in (LOGIN_URL, '/accounts/logout/'):
            return None
        if request.POST.get('this_is_the_login_form'):
            return None
        from local_overrides import ALLOWED_ADMIN_ACTIONS
        if request.POST.get('action') in ALLOWED_ADMIN_ACTIONS:
            return None

        from django.http import HttpResponseForbidden
        return HttpResponseForbidden(self.MESSAGE)

MIDDLEWARE_CLASSES = ('settings.ReadOnlyGuard', 'settings.DisableCsrfCheck') + MIDDLEWARE_CLASSES

# Use non-cached loaders in dev so admin templates are found reliably
TEMPLATE_LOADERS = (
    'django.template.loaders.filesystem.Loader',
    'django.template.loaders.app_directories.Loader',
)

# Explicitly include Django's built-in admin templates
import django as _django
TEMPLATE_DIRS = TEMPLATE_DIRS + (
    os.path.join(os.path.dirname(_django.__file__), 'contrib', 'admin', 'templates'),
)
