WebApp.connectHandlers.use (req, res, next) =>
  req.dynamicHead = req.dynamicHead or ""

  if (cdn_domain = JustdoHelpers.getCDNDomain())?
    req.dynamicHead += """<script>CDN = "#{cdn_domain}"</script>"""

    WebAppInternals.setBundledJsCssUrlRewriteHook (url) => JustdoHelpers.getCDNUrl(url)

  next()