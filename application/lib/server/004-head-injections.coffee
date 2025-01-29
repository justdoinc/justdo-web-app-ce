# We don't use head.html since it doesn't support blaze helpers which we need to set the CDN
# prefix
WebApp.connectHandlers.use (req, res, next) =>
  req.dynamicHead = req.dynamicHead or ""

  req.dynamicHead += """
    <link rel="shortcut icon" sizes="16x16 24x24 32x32 48x48 64x64" href="#{JustdoHelpers.getCDNUrl "/layout/logos-ext/justdo_favicon.ico"}">
    <script src="#{JustdoHelpers.getCDNUrl "/layout/lottie/lottie-player.js"}"></script>
  """

  next()
