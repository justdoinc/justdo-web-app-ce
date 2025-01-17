main_module = APP.modules.main

#
# Real window dim
#
if (/Edge\/\d./i.test(navigator.userAgent))
  # Microsoft Edge
  forced_window_dim_horizontal_offset = -13
  forced_window_dim_vertical_offset = -13
else
  forced_window_dim_horizontal_offset = 0
  forced_window_dim_vertical_offset = 0

getRealWindowDimFromDom = ->
  return {
    width: window.innerWidth + forced_window_dim_horizontal_offset
    height: window.innerHeight + forced_window_dim_vertical_offset
  }

_.extend main_module,
  real_window_dim: new ReactiveVar getRealWindowDimFromDom(), APP.helpers.jsonComp

# real_window_dim update handler
$(window).on "resize", ->
  main_module.real_window_dim.set getRealWindowDimFromDom()


#
# (fake) window dim
#

_.extend main_module,
  custom_window_dim_offset: new ReactiveVar {width: 0, height: 0}, APP.helpers.jsonComp
  custom_window_dim_gravity: new ReactiveVar "nw" # Permitted values nw/ne/se/sw

# We seperate to two _.extend so @real_window_dim and custom_window_dim_offset
# will be available when creating the newComputedReactiveVar
_.extend main_module,
  # window_dim.get() returns a reactive resource that invalidates on changes
  # to both the real_window_dim reactive var and custom_window_dim_offset
  # the returned value is the real window dim - custom window dim offset
  window_dim: APP.helpers.newComputedReactiveVar(
    "window_dim",
    ->
      real_window_dim = main_module.real_window_dim.get()
      custom_window_dim_offset = main_module.custom_window_dim_offset.get()

      return {
        width: real_window_dim.width - custom_window_dim_offset.width
        height: real_window_dim.height - custom_window_dim_offset.height
      }

    , {reactiveVarEqualsFunc: APP.helpers.jsonComp}
  )