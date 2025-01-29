APP.once "both-code-executed", ->
  main_module = APP.modules.main

  template_helpers =
    displayName: JustdoHelpers.displayName

    taskCommonName: JustdoHelpers.taskCommonName

    isUserEmailsVerified: JustdoHelpers.isUserEmailsVerified

    userDateFormat: (value, show_seconds) ->
      return JustdoHelpers.getDateTimeStringInUserPreferenceFormat(value, show_seconds)

    friendlyDateFormat: (date) ->
      return JustdoHelpers.friendlyDateFormat(date)
    
    friendlyTimeFormat: (date, show_seconds) ->
      return JustdoHelpers.friendlyTimeFormat(date, show_seconds)

    currentUserMainEmail: JustdoHelpers.currentUserMainEmail

    getUserMainEmail: -> JustdoHelpers.getUserMainEmail(@)

    currentPageName: JustdoHelpers.currentPageName

    getWindowWidth: -> main_module.window_dim.get().width
    getWindowHeight: -> main_module.window_dim.get().height

    landingAppRootUrl: -> APP.env_rv.get()?.LANDING_APP_ROOT_URL
    webAppRootUrl: -> APP.env_rv.get()?.WEB_APP_ROOT_URL

    getCDNUrl: (path) -> JustdoHelpers.getCDNUrl(path)

  for helper_name, helper of template_helpers
    Template.registerHelper helper_name, helper