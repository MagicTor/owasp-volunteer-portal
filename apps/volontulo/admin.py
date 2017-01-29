# -*- coding: utf-8 -*-

"""
.. module:: admin
"""

from django.contrib import admin

from apps.volontulo.models import *

admin.site.register(UserProfile)
admin.site.register(Organization)
admin.site.register(Offer)
admin.site.register(OfferImage)
admin.site.register(UserGallery)
admin.site.register(OrganizationGallery)
admin.site.register(Page)