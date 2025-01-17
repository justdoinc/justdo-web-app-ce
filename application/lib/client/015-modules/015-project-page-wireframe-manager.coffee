main_module = APP.modules.main
project_page_module = APP.modules.project_page

wireframe_changes_dep = new Tracker.Dependency()

getDim = ($obj) ->
  ret = {
    outerW: $obj.outerWidth()
    outerH: $obj.outerHeight()
    fullOuterW: $obj.outerWidth(true)
    fullOuterH: $obj.outerHeight(true)
  }

  ret.vMargins = ret.fullOuterH - ret.outerH
  ret.hMargins = ret.fullOuterW - ret.outerW

  return ret

_.extend project_page_module,
  projectContainerBelowMinimalWidth: ->
    min_project_container_width = 
      project_page_module.options?.min_project_container_dim?.width or 0

    window_dim = main_module.window_dim.get().width

    return window_dim < min_project_container_width

  invalidateOnWireframeStructureUpdates: -> wireframe_changes_dep.depend()

  wireframeManager: ->
    # Restructure the project page according to user preferences
    # and constrains
    win_dim = APP.modules.main.window_dim.get()
    preferences = project_page_module.preferences.get()
    options = project_page_module.options

    # Main nav-bar
    $header = $("#header")
    # #project-main + #task-pane container
    $project_container = $(".project-container")

    # $project_container should occupy 100% of the space
    # available under header - note that there's no footer
    # in project page
    project_container_dim =
      height: win_dim.height - APP.helpers.getGlobalSassVars().navbar_height - 2
      width: Math.max(options.min_project_container_dim.width, win_dim.width)

    if project_page_module.projectContainerBelowMinimalWidth()
      # If minimal width reached, reduce height by the size of the horizontal
      # scroll (22 chosen according to win 10 scrolls) - so we won't show
      # vertical scrolls just because the horizontal scrolls are showing
      project_container_dim.height -= 21

    $project_container.outerHeight(project_container_dim.height)
    $project_container.outerWidth(project_container_dim.width)

    $project_main = $("#project-main") # project page header + grid
    old_project_main_dim = getDim($project_main)
    $toolbar = $("#task-pane")

    # preferences defaults
    #
    # **If you change defaults update corresponding methods in 025-project-page-template-helpers.coffee**
    if not (preferences.toolbar_position in ["right", "left"])
      preferences.toolbar_position = "right"
    if not (preferences.toolbar_open)?
      preferences.toolbar_open = true

    if preferences.toolbar_position in ["right", "left"]
      custom_dim = "width"
      resizable_handle_position = "w"
      if preferences.toolbar_position == "left"
        resizable_handle_position = "e"
    else
      resizable_handle_position = "n"
      custom_dim = "height"

    if not preferences.toolbar_open
      toolbar_size = 0
      minimal_toolbar_size = 0
      maximal_toolbar_size = 0
    else
      # bare minimum toolbar width/height
      minimal_toolbar_size =
        options.min_toolbar_dim[custom_dim]

      maximal_toolbar_size =
        project_container_dim[custom_dim] - 
          options.min_project_main_size[custom_dim]

      # Maximal rule is stronger in edge cases
      if minimal_toolbar_size > maximal_toolbar_size
        minimal_toolbar_size = maximal_toolbar_size

      toolbar_size =
        Math.min(preferences["toolbar_#{custom_dim}"], maximal_toolbar_size)
      toolbar_size = Math.max(toolbar_size, minimal_toolbar_size)

    project_main_size =
      project_container_dim[custom_dim] - toolbar_size

    # We use "" as initial value so if no value will be given
    # jQuery will initialize the value and the defaults from the
    # css files will be used
    if custom_dim == "width"
      $project_main.outerWidth(project_main_size)
      $toolbar.outerWidth(toolbar_size)
      $project_main.outerHeight("")
      $toolbar.outerHeight(project_container_dim.height - APP.helpers.getGlobalSassVars().project_header_height)
    else
      $project_main.outerWidth("")
      $toolbar.outerWidth("")
      $project_main.outerHeight(project_main_size)
      $toolbar.outerHeight(toolbar_size)

    project_main_dim = getDim($project_main)

    project_main_responsive_states = _.keys options.project_main_responsive_states
    for state, max_state_size of options.project_main_responsive_states
      if project_main_dim.outerW <= max_state_size 
        other_states = _.without project_main_responsive_states, state
        $project_main.removeClass other_states.join(" ")
        $project_main.addClass state

        break
      else
        $project_main.removeClass state


    # Resize grid
    $below_project_header_items = $(".below-project-header-items")
    below_project_header_items_dim = getDim($below_project_header_items)
    $tabs_containers = $(".grid-control-tab")
    old_tasks_grid_dim = getDim($tabs_containers)
    $tabs_containers.outerHeight(project_main_dim.outerH - below_project_header_items_dim.fullOuterH - old_tasks_grid_dim.vMargins - APP.helpers.getGlobalSassVars().project_header_height)
    if (grid_control = project_page_module.gridControl())?
      grid_control._grid.resizeCanvas(false) # update_row_count=false

    # Take care of toolbar resizing feature
    $resizer = $(".task-pane-resizable", $toolbar)
    setTaskPaneResizerResizableClasses = (position) ->
      # Arguments:
      #
      # Position should be a valid jQuery-ui's resizable `handles` option
      # - only String values are supported, don't pass object.
      # http://api.jqueryui.com/resizable/#option-handles
      #
      # If null is passed, all the existing jQuery-ui's resizable classes
      # will be removed from the resizer - important to do it before
      # destroyResizable() as these element will be removed by Resizable otherwise.

      if position?
        $resizer
          .addClass("ui-resizable-handle")
          .addClass("ui-resizable-#{position}")
        $resizer.attr("position", position)
      else
        # Remove all ui-resizable classes
        _.each $resizer.attr("class")?.split(' '), (class_name) ->
          if /ui-resizable.*/.test(class_name)
            $resizer.removeClass(class_name)
        $resizer.removeAttr("position")

      return


    toolbarResizableExists = -> $toolbar.resizable("instance")?
    destroyResizable = ->
      setTaskPaneResizerResizableClasses(null)

      if toolbarResizableExists()
        $toolbar.resizable("destroy")
    setupResizable = ->
      # Destory resizable if exists
      destroyResizable()

      setTaskPaneResizerResizableClasses(resizable_handle_position)

      # resizable_options = 
      #   handles: resizable_handle_position

      resizable_options = 
        handles: {}

      resizable_options.handles[resizable_handle_position] = ".task-pane-resizable"

      if custom_dim == "width"
        resizable_options.minWidth = minimal_toolbar_size
        resizable_options.maxWidth = maximal_toolbar_size
        resizable_options.resize = (event, ui) ->
          project_page_module.updatePreferences({toolbar_width: ui.size.width})
          $toolbar.css({right: "", left: ""})
      else
        resizable_options.minHeight = minimal_toolbar_size
        resizable_options.maxHeight = maximal_toolbar_size
        resizable_options.resize = (event, ui) ->
          project_page_module.updatePreferences({toolbar_height: ui.size.height})
          $toolbar.css({top: ""})

      $toolbar.resizable resizable_options

      return

    if minimal_toolbar_size == maximal_toolbar_size
      # This is true when the toolbar is closed (see `if not preferences.toolbar_open` above)
      #
      # We destroy since we don't want the user to change
      # preferences when it's impossible to resize / the toolbar is closed.
      destroyResizable()
    else if not toolbarResizableExists()
      setupResizable()
    else if $resizer.attr("position") != resizable_handle_position
      # if toolbar position changed
      setupResizable()
    else if custom_dim == "width" and
        (
          $toolbar.resizable("option", "minWidth") != minimal_toolbar_size or
          $toolbar.resizable("option", "maxWidth") != maximal_toolbar_size
        )
      setupResizable()
    else if custom_dim == "height" and
        (
          $toolbar.resizable("option", "minHeight") != minimal_toolbar_size or
          $toolbar.resizable("option", "maxHeight") != maximal_toolbar_size
        )
      setupResizable()

    wireframe_changes_dep.changed()

    return

  wireframeManagerComputation: null

  initWireframeManager: ->
    if not project_page_module.wireframeManagerComputation?
      project_page_module.wireframeManagerComputation = Tracker.autorun ->
        project_page_module.wireframeManager()
    else
      project_page_module.logger.warn "wireframeManager already initiated"

  stopWireframeManager: ->
    if project_page_module.wireframeManagerComputation?
      project_page_module.wireframeManagerComputation.stop()

      project_page_module.wireframeManagerComputation = null