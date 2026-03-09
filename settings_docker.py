# -*- coding: utf-8 -*-
"""
Docker-specific Django settings for local development.
Imports everything from settings_global, then overrides for a
self-contained SQLite-based environment.
"""
from settings_global import *

DEBUG = True
TEMPLATE_DEBUG = DEBUG

# SQLite database — no external DB server needed
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': '/app/data/dev.db',
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

# Use file-based sessions (default dir works in Docker)
SESSION_ENGINE = "django.contrib.sessions.backends.file"

# Dummy search engine (no Xapian needed)
HAYSTACK_SEARCH_ENGINE = "dummy"

# Allow all hosts for local dev
ALLOWED_HOSTS = ['*']

# Exempt all URLs from login requirement for easier local browsing
LOGIN_EXEMPT_URLS = (r'.*',)

# Use Docker-specific URL conf that adds static file serving
ROOT_URLCONF = 'urls_docker'
