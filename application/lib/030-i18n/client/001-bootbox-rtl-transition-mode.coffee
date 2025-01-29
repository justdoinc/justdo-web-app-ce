# Our Bootbox fork has a logic to automatically add the dir="rtl", and other RTL related classes, and variations.
#
# The web-app developed long before the RTL support, and we have to gradually add the RTL support to its bootboxes -
# many of which aren't RTL ready yet.
#
# This method prevents the automatic RTL support for bootbox, to allow gradual RTL support on the web-app level.
#
# Bootboxes that we ensured to be RTL ready, will have the {rtl_ready: true} option, and will show on RTL mode when
# the lang is RTL.
bootbox.rtlTransitionMode true