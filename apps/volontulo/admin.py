# -*- coding: utf-8 -*-

"""
.. module:: admin
"""

from django.contrib import admin

from apps.volontulo.models import (
    UserProfile,
    Organization,
    Offer,
    OfferImage
)


admin.site.register(UserProfile)
admin.site.register(Organization)
admin.site.register(Offer)
admin.site.register(OfferImage)
