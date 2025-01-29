project_page_module = APP.modules.project_page

prepareOpreqArgs = JustdoHelpers.prepareOpreqArgs

_.extend project_page_module,
  # Read operations_prereq.coffee on grid-control package for elaborate
  # discussion about operations prerequisites

  _opreqGridInitialized: (prereq) ->
    prereq = prepareOpreqArgs(prereq)

    if not project_page_module.gridReady()
      prereq.grid_not_init = "Loading grid..."

    return prereq
