window.js_started = new Date()

InjectData.getData "env", (env) ->
  window.env = env

  APP.emit "env-vars-ready", env

  return