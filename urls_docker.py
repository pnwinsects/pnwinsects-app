# -*- coding: utf-8 -*-
"""
Docker URL conf — wraps the main urls.py and adds static/media file serving
for the Django development server.
"""
from urls import *
from django.conf import settings
from django.conf.urls.defaults import patterns

# Serve media files (CSS, JS, images) from MEDIA_ROOT in development
if settings.DEBUG:
    urlpatterns = patterns('',
        (r'^media/(?P<path>.*)$', 'django.views.static.serve',
         {'document_root': settings.MEDIA_ROOT}),
    ) + urlpatterns
