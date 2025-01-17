# This tracker is responsible for adding the RTL support to the body tag, based on the current language direction.
Tracker.autorun ->
  if APP.justdo_i18n.isRtl Router?.current()?.route?.getName()
    $("body").attr("dir", "rtl")
    $("body").addClass("right-to-left")
  else
    $("body").attr("dir", "ltr")
    $("body").removeClass("right-to-left")

  return