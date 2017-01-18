"""
Vagrant-based Development Settings Module
"""
from volontulo_org.settings.dev import *


DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql_psycopg2',
        'NAME': 'volontulo',
        'USER': 'volontulo',
        'PASSWORD': 'volontulo',
        'HOST': '127.0.0.1',
        'PORT': '5432',
    }
}
