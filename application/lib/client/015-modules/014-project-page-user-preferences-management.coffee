project_page_module = APP.modules.project_page

_.extend project_page_module,
  loadPreferences: ->
    default_preferences = 
      toolbar_position: APP.justdo_i18n.getRtlAwareDirection project_page_module.options.default_toolbar_position
      toolbar_height: project_page_module.options.default_toolbar_height
      toolbar_width: project_page_module.options.default_toolbar_width

    stored_preferences = amplify.store project_page_module.options.pref_local_storage_name

    if not stored_preferences? or not _.isObject(stored_preferences)
      return default_preferences

    return _.extend(default_preferences, stored_preferences)

  updatePreferences: (new_pref) ->
    new_pref = _.extend {}, project_page_module.preferences.get(), new_pref
    project_page_module.preferences.set new_pref
    amplify.store project_page_module.options.pref_local_storage_name, new_pref

    return

project_page_module.preferences = new ReactiveVar project_page_module.loadPreferences(), APP.helpers.jsonComp
# This tracker is to allow the reactivity of APP.justdo_i18n.getRtlAwareDirection to change the toolbar position
# when the language changes from LTR to RTL or vice-versa
rtl_toolbar_position_tracker = Tracker.autorun -> project_page_module.preferences.set project_page_module.loadPreferences()
