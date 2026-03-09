FROM python:2.7

# Fix apt sources — Debian Stretch is archived
RUN sed -i 's|deb.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i 's|security.debian.org|archive.debian.org|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list 2>/dev/null; \
    apt-get update && apt-get install -y --no-install-recommends \
        libjpeg-dev \
        zlib1g-dev \
        libfreetype6-dev \
    && rm -rf /var/lib/apt/lists/*

# Pin pip and setuptools to last Python 2.7-compatible versions
RUN pip install --upgrade "pip==20.3.4" "setuptools<45"

WORKDIR /app

# Install Python dependencies
COPY requirements-docker.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Copy application code
COPY . /app/

# Replace broken settings.py symlink with Docker-specific settings
COPY settings_docker.py /app/settings.py

# Create stub modules for packages that aren't pip-installable but are imported
RUN mkdir -p /usr/local/lib/python2.7/site-packages/admin_sentry && \
    echo "urls = __import__('django.conf.urls.defaults', fromlist=['patterns']).patterns('')" \
      > /usr/local/lib/python2.7/site-packages/admin_sentry/__init__.py && \
    echo "urlpatterns = __import__('django.conf.urls.defaults', fromlist=['patterns']).patterns('')" \
      > /usr/local/lib/python2.7/site-packages/admin_sentry/urls.py && \
    mkdir -p /usr/local/lib/python2.7/site-packages/csvimporter && \
    echo "urls = __import__('django.conf.urls.defaults', fromlist=['patterns']).patterns('')" \
      > /usr/local/lib/python2.7/site-packages/csvimporter/__init__.py && \
    echo "urlpatterns = __import__('django.conf.urls.defaults', fromlist=['patterns']).patterns('')" \
      > /usr/local/lib/python2.7/site-packages/csvimporter/urls.py && \
    mkdir -p /usr/local/lib/python2.7/site-packages/csv_admin && \
    touch /usr/local/lib/python2.7/site-packages/csv_admin/__init__.py

# Prepare entrypoint
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN sed -i 's/\r$//' /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

EXPOSE 8000

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
