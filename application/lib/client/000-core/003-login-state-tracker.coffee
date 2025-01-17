#
# Follow APP.login_state and react to changes
#

#
# Helpers
#
redirectToLandingApp = (post_login_url) ->
  if not (landing_app_root_url = window.env?.LANDING_APP_ROOT_URL)?
    APP.logger.info "Can't redirect to the landing page, env var LANDING_APP_ROOT_URL is not defined"

    return

  APP.justdo_analytics.JA({cat: "core", act: "redirect-jd-env"})

  window.location = APP.login_target.applyTargetUrl(landing_app_root_url, post_login_url)

  return

#
# Trackers
#

original_requested_location = window.location.href
Tracker.autorun ->
  login_state = APP.login_state.getLoginState()
  login_state_sym = login_state[0]

  #
  # logged-out state redirection back to landing app
  #
  if login_state_sym == "logged-out"
    if APP.login_state.isInitialLoginState()
      # If a user requested a page as a logged-out, bring
      # him back to that page following login.
      redirectToLandingApp(original_requested_location)
    else
      # Regular, not init, logged-out
      redirectToLandingApp()

  #
  # logged-out state redirection back to landing app
  #
  if login_state_sym == "logged-in"
    user = login_state[1]

    if APP.projects.userRequirePostRegistrationInit()
      APP.logger.debug "Performing justdo projects post registration init"

      APP.projects.postRegInit (err, initiation_report) ->
        if err?
          console.error err
        APP.projects.emit "post-reg-init-completed", initiation_report
        APP.logger.debug "Done performing post registration init"

        if (first_project_id = initiation_report?.first_project_created)? and first_project_id != false
          if JustdoHelpers.currentPageName() != JustdoAffiliatesProgram?.plugin_page_id
            # If the use is in the promoters page (i.e. he is a Promoter in  the promoter page, right after registration, do not redirect to the first created project)
            Router.go "project", {_id: first_project_id}
    else
      APP.projects.handleJdCreationRequest (err, created_project_id) ->
        if err?
          console.error err
        
        APP.projects.emit "post-handle-jd-creation-request", created_project_id
        if not created_project_id?
          return
        
        Router.go "project", {_id: created_project_id}
        
        return