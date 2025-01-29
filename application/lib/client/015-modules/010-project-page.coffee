project_page_module = APP.helpers.initModule "project_page", "Project Page"

options =
  pref_local_storage_name: "project-page-preferences"

  default_toolbar_position: "right"
  default_toolbar_height: 300
  # Width was chosen as the minimal width in which description
  # editor shows toolbars in only two lines - a bit more space given
  # to avoid 3 lines of toolbars in case task pane has scrollbar
  default_toolbar_width: 430

  # The minimal width for the project container
  min_project_container_dim:
    width: APP.helpers.getGlobalSassVars().min_layout_width

  # The minimal task pane width/height
  min_toolbar_dim:
    height: 300 # relevant when bottom only
    # Important if you change this option change also relevant
    # `#task-pane .container-fluid` in project.sass
    width: 430 # relevant when right/left only

  # The minimal space for the main area if not enough space for
  # both toolbar and project_main minimal, project_main is stronger
  # toolbar will be less than minimal
  min_project_main_size:
    height: 200
    width: 695

_.extend options,
  project_main_responsive_states:
    # "project-main-tiny": options.min_project_container_dim.width - options.min_project_main_size.width - 5 # This basically disables tiny mode
    "project-main-xsm": 820

_.extend project_page_module,
  options: options

  # project stores the object returned by Projects.load_project for the current route
  # can be either null or a rective var
  # We use project_page_module.project to diffrentiate project page creating
  # and project switching while remaining in the project page.
  # If project_page_module.project is null we assume project page just got created,
  # if not null we assume switching: see Template.project.created

  # Being assigned/reset in: Template.project.created/destroyed
  project: new ReactiveVar null, (a, b) -> a == b

  # Core project config ui sections and templates are in the
  # justdo-core-project-configurations
  project_config_ui: new JustdoProjectConfigUI()

  # Being assigned/reset in: Template.project_grid.created/destroyed
  grid_control_mux: new ReactiveVar null, (a, b) -> a == b

  search_comp: null
  owner_setter_manager: null

  #
  # errors types
  #
  _errors_types:
    # In an effort to encourage standardizing errors types we will issue a warning
    # if an error of type other than the following will be used
    # The value is the default message
    "unknown-data-context": "Unknown Data Context"

  #
  # Helpers
  #
  helpers:
    curProj: -> project_page_module.curProj() # XXX obsolete way to call this method, use core api directly

    augment_members_field: (members_array, find_options, options) ->
      if not members_array? or _.isEmpty(members_array)
        return []

      # Gets an array of members in the members field format and augment it with the members data
      # from the users collection

      if not find_options?
        find_options = {}
      else
        find_options = _.extend {}, find_options

      # We are using options of getUsersDocsByIds that doesn't allow setting fields to increase speed.
      if find_options.fields?
        find_options.fields = undefined

      default_options =
        allow_modifying_input: true
      options = _.extend default_options, options

      members_users_docs =
        JustdoHelpers.getUsersDocsFromProjectMembersArray(members_array, {ret_type: "object", user_fields_reactivity: false, missing_users_reactivity: true, get_docs_by_reference: true, find_options: find_options})

      return _[if options.allow_modifying_input then "map" else "each"] members_array, (member) ->
        if (user_doc = members_users_docs[member.user_id])?
          if options.allow_modifying_input
            return Object.assign(member, user_doc)
          else
            return _.extend {}, member, user_doc
        else
          return member # return as is if we couldn't find the user in the members_users_docs

  #
  # Core API
  #
  curProj: -> @project.get()

  getGridControlMux: -> @grid_control_mux.get()

  gridControl: (require_grid_control_ready=true) ->
    # Returns the grid control of the current active tab of
    # @grid_control_mux (might be null if no tab is active,
    # if @grid_control_mux isn't init, etc.)

    # if require_grid_control_ready is true, null will return
    # if the tab isn't ready.
    #
    # if require_grid_control_ready is false, the current
    # grid control of the tab will be returned regardless
    # of state (will be null if not loaded yet)

    if (gcm = @grid_control_mux.get())?
      return gcm.getActiveGridControl(require_grid_control_ready)

    return null

  mainGridControl: ->
    # Returns the "main" tab's grid control object, regardless of the active
    # grid control.

    if (gcm = @grid_control_mux.get())?
      return gcm.getMainGridControl(true)

    return null

  mainGridData: ->
    if not (main_grid_control = @mainGridControl())?
      return null

    return main_grid_control._grid_data

  gridData: ->
    if not (grid_control = @gridControl())?
      return null

    return grid_control._grid_data

  gridReady: -> @gridControl()?

  getCurrentGcm: -> @grid_control_mux.get()

  getCurrentTab: ->
    gcm = @getCurrentGcm()

    return gcm?.getActiveTab()

  getCurrentTabState: ->
    gcm = @getCurrentGcm()

    return gcm?.getActiveTabState()

  getCurrentTabId: ->
    return @getCurrentTab()?.tab_id

  getCurrentTabSectionsState: ->
    gcm = @getCurrentGcm()

    return gcm?.getActiveGridControlSectionsState()

  activeItemPath: ->
    # Returns the current item id, if current item is a @collection item
    if not (grid_control = @gridControl())?
      return null

    if grid_control.isMultiSelectMode()
      return null

    return grid_control.getCurrentPath()

  activeItemId: ->
    if not (grid_control = @gridControl())?
      return null

    if not (active_item_path = @activeItemPath())?
      return null

    tree_info = grid_control._grid_data.getPathNaturalCollectionTreeInfo(active_item_path)

    if not tree_info?
      return null

    return tree_info.item_id

  activeItemObj: (fields, _grid_data_structure=true) ->
    # Returns the object of the current active item of the grid.
    #
    # if _grid_data_structure is set to false, we will attempt to fetch the
    # item from the Mongo collection and not from the grid-data's internal
    # data structures
    #
    # WARNING: activeItemObj is reactive to the provided fields *only* if _grid_data_structure
    # is set to false.
    #
    # fields: Mongo Field Specifier
    if not (grid_control = @gridControl())?
      return null

    if _grid_data_structure
      return grid_control.getCurrentPathObj(fields)

    # Get data from the collection, not from grid-data's internal data
    # structures
    if not (active_item_id = @activeItemId())?
      @logger.debug "activeItemObj can't find the active item collection_id"
      return null

    return APP.collections.Tasks.findOne(active_item_id, {fields: fields})

  activeItemObjFromCollection: (fields) ->
    # Returns the up-to-date version of the current item obj from Mongo colleciton
    @activeItemObj(fields, false)

  tab_with_potential_path: /[&?]t(?:ab)?=([^&]+)(?:&p(?:ath)?=([^&]+))?/
  # Will accept query string that has:
  # ...&tab=tab_id&path=/path/...
  # ...&tab=tab_id...
  # Notes:
  # * path must come immediately *after* tab
  # * the letter t can be used instead of tab
  # * the letter p can be used instead of tab
  # * & or ? must come before tab
  path_only: /path=([^&]+)/
  # Will accept query string that has:
  # ...&path=/path/...
  # Notes:
  # * This is mostly for backward compatibility
  # * & or ? must come before tab
  getPathFromQueryString: (query_string) ->
    # Returns: [tab_id, path]
    #
    # Will return null if no match
    #
    # Might return:
    # [null, path] - if only path provided (backward compatibility)
    # [tab_id, undefined] - if only tab provided

    tab_id = path = null

    # First try to look for both tab with path
    if (res = @tab_with_potential_path.exec(query_string))?
      [m, tab_id, path] = res
    else if (res = @path_only.exec(query_string))?
      [m, path] = res
    else
      # No match
      return null

    return [tab_id, path]

  sections_state_regex: /s_([^_&=]+)_([^_&=]+)=([^&=]+)/g
  getSectionsStateFromQueryString: (query_string) ->
    # Extract from the query string arguments of the form:
    # s_{section_id}_{section_var}={section_val}
    # section_val is assumed to be output in encodeURIComponent
    # format.
    #
    # Returns: {section_id: {state_var: val, ...}, ...}
    #
    # Will return null if no match

    sections_state = {}
    while (result = @sections_state_regex.exec(query_string))?
      Meteor._ensure sections_state, result[1]
      sections_state[result[1]][result[2]] = decodeURIComponent(result[3])

    return sections_state

  setupProjectCustomFeatureOnProjectPage: (custom_feature_id, callbacks) ->
    # callbacks must be an object that includes two callbacks: installer() and destroyer()
    # we don't validate the input.
    #
    # Will call callbacks.installer when:
    #
    #  * Switching to a project where custom feature is enabled (either on first load of project page, or when another project is loaded).
    #
    # Will call callbacks.destroyer when:
    #
    #  * Switching to a project where it is disabled from a project where it was enabled.
    #  * When moving from the project page to another page, when the custom feature was enabled for the last loaded project.
    #
    # Returns the computation object of the autorun we set.

    last_project_id = null # null means we had not project before (we were in another type of page, or first load)
    last_feature_state = null # null or "enabled"/"disabled"; will be null if last_project_id is null

    return Tracker.autorun =>
      project_obj = APP.modules.project_page.curProj()

      if project_obj?
        project_id = project_obj.id
        feature_state =
          if project_obj.isCustomFeatureEnabled(custom_feature_id) then "enabled" else "disabled"
      else
        project_id = null
        feature_state = null

      if not project_id?
        if last_project_id?
          if last_feature_state == "enabled"
            # We switched to another page type, from a project that had the custom feature
            # enabled, destroy.
            Tracker.nonreactive ->
              return callbacks.destroyer()
      else
        # We are under the project page.
        if feature_state == "enabled" and (last_feature_state == "disabled" or last_feature_state == null)
          # Install either if we were under no project before (first switch to the project page),
          # or if we switched from a project were disabled.
          Tracker.nonreactive ->
            return callbacks.installer()

        if feature_state == "disabled" and last_feature_state == "enabled"
          # Destroy only if been enabled before
          Tracker.nonreactive ->
            return callbacks.destroyer()

      last_project_id = project_id
      last_feature_state = feature_state

      return

  activateTaskInProject: (project_id, task_id, onActivated, timeout) ->
    return APP.projects.activateTaskInProject(project_id, task_id, onActivated, timeout)