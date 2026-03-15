# -*- coding: utf-8 -*-
"""
Docker URL conf — wraps the main urls.py and adds static/media file serving
for the Django development server.
"""
from urls import *
import os
import django
from django.conf import settings
from django.conf.urls.defaults import patterns

# Serve media files (CSS, JS, images) from MEDIA_ROOT in development
if settings.DEBUG:
    admin_media_root = os.path.join(os.path.dirname(django.__file__), 'contrib', 'admin', 'media')
    urlpatterns = patterns('',
        # Django admin media (CSS/JS for the admin UI)
        (r'^media/admin/(?P<path>.*)$', 'django.views.static.serve',
         {'document_root': admin_media_root}),
        # All other media files
        (r'^media/(?P<path>.*)$', 'django.views.static.serve',
         {'document_root': settings.MEDIA_ROOT}),
    ) + urlpatterns
