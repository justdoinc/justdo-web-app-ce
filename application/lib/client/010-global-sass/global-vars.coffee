# IMPORTANT! If you change any of the vars below you must update global-vars.sass

_.extend APP.helpers,
  getGlobalSassVars: ->
    return {
      min_layout_width: 1150 + 24 # header.sass .project-header min-width's value + 24
      navbar_height: 45
      project_header_height: 45
    }