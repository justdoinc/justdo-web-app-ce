main_module = APP.helpers.initModule "main", "Main"

JustdoHelpers.setupPlaceholdersReactiveListRegistry(main_module)

#
# helpers
#
_.extend main_module,
  toggleGhostMode: -> $("html").toggleClass("ghost")

Tracker.autorun (c) ->
  if not (landing_app_root_url = APP.env_rv.get()?.LANDING_APP_ROOT_URL)?
    return

  c.stop()

  JD.registerPlaceholderItem "terms-and-conditions",
    data:
      html: """
        <a href="#{landing_app_root_url}/terms-and-conditions" target="_blank"><i class="fa fa-file-text" aria-hidden="true"></i>Terms &amp; Conditions</a>
      """

    domain: "drawer-bottom"
    position: 100

  JD.registerPlaceholderItem "copyright-notice",
    data:
      html: """
        <a href="#{landing_app_root_url}/copyright-notice" target="_blank"><i class="fa fa-copyright" aria-hidden="true"></i>Copyright</a>
      """

    domain: "drawer-bottom"
    position: 100
