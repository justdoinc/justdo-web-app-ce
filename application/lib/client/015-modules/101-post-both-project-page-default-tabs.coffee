# Read about "both-code-executed" in /020-both/999-emit-both-code-executed.coffee
APP.once "both-code-executed", ->
  project_page_module = APP.modules.project_page

  gcOpsGen = project_page_module.generateGridControlOptionsForSections

  #
  # Tabs sections definitions
  #
  default_tabs_sections = []

  #
  # main tab sections
  #
  default_tabs_sections["main"] =
    sections: [
      {
        id: "main"

        section_manager: "DataTreeSection"

        options:
          permitted_depth: 0
      }
      {
        id: "s"

        # Implemented in stem-capital:projects's /lib/client/grid-sections/
        section_manager: "JustdoProjectsDetachedDataSubTreesSection"

        options:
          permitted_depth: 1
          section_item_title: "Shared With Me"
          expanded_on_init: true

        section_manager_options:
          root_items_sort_by: (item) -> item.seqId
      }
      {
        id: "my-direct-tasks"

        section_manager: "MyDirectTasksSection"

        options:
          permitted_depth: 1
          permitted_depth_removeSpecialCase: (tree_row_id) ->
            # Under this section, we allow removing collection
            # items in any level, as long as other rules (e.g has
            # children) not preventing it.

            return true

          section_item_title: "My Direct Tasks"

      }
      {
        id: "members-direct-tasks"

        section_manager: "MembersDirectTasksSection"

        options:
          permitted_depth: 2
          permitted_depth_removeSpecialCase: (tree_row_id) ->
            # Under this section, we allow removing collection
            # items in any level, as long as other rules (e.g has
            # children) not preventing it.
            
            return true

          section_item_title: "Members' Direct Tasks"

      }
      {
        id: "t"

        # Implemented in stem-capital:projects's /lib/client/grid-sections/
        section_manager: "TicketsQueueSection"

        section_manager_options:
          root_items_sort_by: (item) -> item.title

        options:
          permitted_depth: 2
          section_item_title: "Ticket Queues"
      }
    ]


  #
  # Sub-tree tab sections
  #
  sub_tree_tab_id = "sub-tree"
  default_tabs_sections[sub_tree_tab_id] =
    sections: [
      {
        id: "main"

        section_manager: "DataTreeSection"

        options:
          permitted_depth: 1
          sectionInit: (section) ->
            root_item_change_comp_encountered_root_items = new Set()

            root_item_change_comp = Tracker.autorun =>
              # Expand the sub-tree root item if we show it for the first time
              if @grid_control?.grid_control_mux?.getActiveTab()?.tab_id != sub_tree_tab_id
                return

              if @grid_control?.grid_control_mux?.getActiveTabState() != "ready"
                return

              if (root_item = @getGlobalStateVar("root-item"))?
                if not root_item_change_comp_encountered_root_items.has(root_item)
                  root_item_change_comp_encountered_root_items.add(root_item)

                  @expandPath "/#{root_item}/"

              return

            @onDestroy ->
              root_item_change_comp.stop()

              return

            last_root_item = null
            last_loaded_view_for_root_item = {}
            root_item_view_maintainer_comp = Tracker.autorun =>
              # Keep the current zoomed-in tab view in the local storage upon change
              # load from memory on initial load, use a default view if there's no
              # memory entry (to avoid taking another zoom-in tab's view state).
              if @grid_control?.grid_control_mux?.getActiveTab()?.tab_id != sub_tree_tab_id
                return

              if @grid_control?.grid_control_mux?.getActiveTabState() != "ready"
                return

              current_view = @grid_control.getViewReactive()

              if (root_item = @getGlobalStateVar("root-item"))?
                root_item_switched = false

                if root_item != last_root_item
                  last_root_item = root_item

                  root_item_switched = true

              justdo_id = Tracker.nonreactive -> JD.activeJustdo({_id: 1})._id
              amplify_key = "sub-tree-tab-view-state-#{justdo_id}-#{root_item}"

              setView = (view) =>
                @grid_control.setView(view)
                last_loaded_view_for_root_item[root_item] = view

                return

              if not root_item_switched
                if not JustdoHelpers.jsonComp(current_view, last_loaded_view_for_root_item[root_item])
                  # If the view changed, store it, otherwise do nothing (prevents saving the default view redundantly)

                  amplify.store(amplify_key, current_view)
              else
                if (stored_view = amplify.store(amplify_key))?
                  setView(stored_view)
                else
                  setView(APP.modules.project_page.gridControl()._getDefaultView())

              return

            @onDestroy ->
              root_item_view_maintainer_comp.stop()

              return

            return

        section_manager_options:
          rootItems: ->
            if (root_item = @getGlobalStateVar("root-item"))?
              return [{_id: root_item, ignore_archive: true}]
            else
              return []
      }
    ]

  #
  # favorites tab sections
  #
  default_tabs_sections["favorites"] =
    sections: [
      {
        id: "main"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Team Tasks Awaiting Transfer"

        section_manager_options:
          query: ->
            query = {project_id: getCurrentProjectId(), "priv:favorite": {$ne: null}}

            sort = {}
            sort["priv:favorite"] = -1

            return APP.collections.Tasks.find(
              query,
              {sort: sort}
            ).fetch()
      }
    ]

  #
  # tickets-queues tab sections
  #
  default_tabs_sections["tickets-queues"] =
    sections: [
      {
        id: "main"

        # Implemented in stem-capital:projects's /lib/client/grid-sections/
        section_manager: "TicketsQueueSection"

        options:
          permitted_depth: 1

        # # This sort is already the default
        # section_manager_options:
        #   root_items_sort_by: (item) -> item.seqId
      }
    ]

  #
  # due-list tab sections
  #

  # shortcuts
  date_time_format = "YYYY-MM-DD"
  projects_due_lists_module = APP.projects.modules.due_lists
  gridSectionDueListQuery =
    _.bind projects_due_lists_module.gridSectionDueListQuery, projects_due_lists_module
  gridSectionStartDateQuery =
    _.bind projects_due_lists_module.gridSectionStartDateQuery, projects_due_lists_module
  gridSectionPrioritizedItemsQuery =
    _.bind projects_due_lists_module.gridSectionPrioritizedItemsQuery, projects_due_lists_module
  gridSectionAllInProgressItemsQuery =
    _.bind projects_due_lists_module.gridSectionAllInProgressItemsQuery, projects_due_lists_module

  getCurrentProjectId = -> project_page_module.curProj()?.id

  getCurrentProjectProjectsArray = ->
    if (project_id = getCurrentProjectId())?
      return [project_id]

    return []

  addProjectIdToQuery = (query) ->
    # Edits query in-place

    if (project_id = getCurrentProjectId())?
      query.project_id = project_id

    return

  getDateReactive = (section_manager_obj, days_offset=0) ->
    # Returns the current date + days_offset in the "YYYY-MM-DD"
    # format, check every minute if date changed,
    # if it did, invalidates

    # Important! expect @ to be the section manager obj

    # To make sure crv is created only once per section
    # we are creating it once and binding it to the manager
    # (otherwise the redundant setIntervals will be created
    # by the crv manager).
    # Note that query can be called many times between
    # rebuild, we don't want to create redundant crvs,
    # only one.

    # Init a unified construction to hold all the crvs for
    # all the offsets required for this section. If not
    # created already.
    if not (date_crvs = section_manager_obj.date_crvs)?
      date_crvs = section_manager_obj.date_crvs = {}

    # Create the unified date crvs stopper
    if not (stop_date_crvs = section_manager_obj.stop_date_crvs)?
      stop_date_crvs = section_manager_obj.stop_date_crvs = _.once ->
        for date_crv_offset, date_crv of section_manager_obj.date_crvs
          date_crv.stop()

    if not (date_crv = section_manager_obj.date_crvs[days_offset])?
      date_crv = JustdoHelpers.newComputedReactiveVar null, ->
        moment().add(days_offset, "days").format(date_time_format)
      , recomp_interval: 60 * 1000 # once a minute, check whether a recomp is needed

      section_manager_obj.once "destroy", ->
        section_manager_obj.stop_date_crvs()

      section_manager_obj.date_crvs[days_offset] = date_crv

    return date_crv.getSync()

  getOwnersArrayFromGlobalOwnersSectionVar = (section_manager) ->
    owners = section_manager.getGlobalStateVar "owners", Meteor.userId()

    return owners.split(",")

  default_tabs_sections["due-list"] =
    sections: [
      {
        id: "today"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Today's Tasks"
          expanded_on_init: true
          show_if_empty: true

        section_manager_options:
          query: ->
            due_list_conf = 
              owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
              dates: getDateReactive(@) # today
              projects: getCurrentProjectProjectsArray()

            if APP.justdo_private_follow_up.pluginEnabledForActiveProject()
              if due_list_conf.owners.length == 1 and due_list_conf.owners[0] == Meteor.userId()
                due_list_conf.include_my_private_follow_ups = true

            return gridSectionDueListQuery @, due_list_conf
      }
      {
        id: "starting-today"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Starting Today"
          expanded_on_init: true
          show_if_empty: false

        section_manager_options:
          query: ->
            due_list_conf = 
              owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
              dates: getDateReactive(@)
              projects: getCurrentProjectProjectsArray()

            return gridSectionStartDateQuery(@, due_list_conf)
      }
      {
        id: "active-tasks"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Active Tasks by Start Date"
          expanded_on_init: false
          show_if_empty: false

        section_manager_options:
          query: ->
            due_list_conf = 
              owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
              dates: [null, getDateReactive(@)] 
              projects: getCurrentProjectProjectsArray()

            return gridSectionStartDateQuery(@, due_list_conf)
      }
      {
        id: "past-due"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Past Due Tasks"
          expanded_on_init: true
          show_if_empty: true

        section_manager_options:
          query: ->
            due_list_conf = 
              owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
              # past due tasks, not including tasks that has follow up in next 7 days and due to today
              dates: [undefined, getDateReactive(@, -1), getDateReactive(@)] # all until yesterday
              projects: getCurrentProjectProjectsArray()

            if APP.justdo_private_follow_up.pluginEnabledForActiveProject()
              if due_list_conf.owners.length == 1 and due_list_conf.owners[0] == Meteor.userId()
                due_list_conf.include_my_private_follow_ups = true

            return gridSectionDueListQuery(@, due_list_conf)
      }
      {
        id: "all-in-progress"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "All In Progress Tasks"
          expanded_on_init: true

        section_manager_options:
          query: ->
            due_list_conf = 
              owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
              projects: getCurrentProjectProjectsArray()

            return gridSectionAllInProgressItemsQuery(@, due_list_conf)
      }
      {
        id: "7-days"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Upcoming Tasks (7 days)"

        section_manager_options:
          query: ->
            due_list_conf = 
              owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
              # next 7 days, not including tasks that has follow up in next 7 days and due to today
              dates: [getDateReactive(@, 1), getDateReactive(@, 7), getDateReactive(@)] 
              include_start_date: true
              projects: getCurrentProjectProjectsArray()

            if APP.justdo_private_follow_up.pluginEnabledForActiveProject()
              if due_list_conf.owners.length == 1 and due_list_conf.owners[0] == Meteor.userId()
                due_list_conf.include_my_private_follow_ups = true

            return gridSectionDueListQuery(@, due_list_conf)
      }
      # {
      #   id: "top-priority"

      #   section_manager: "QuerySection"

      #   options:
      #     permitted_depth: 1
      #     section_item_title: "Prioritized Tasks (no date assigned)"

      #   section_manager_options:
      #     query: ->
      #       priotized_items_conf = 
      #         owners: getOwnersArrayFromGlobalOwnersSectionVar(@)
      #         limit: 20

      #       if APP.justdo_private_follow_up.pluginEnabledForActiveProject()
      #         if priotized_items_conf.owners.length == 1 and priotized_items_conf.owners[0] == Meteor.userId()
      #           priotized_items_conf.ignore_my_private_follow_ups = true

      #       return gridSectionPrioritizedItemsQuery(@, priotized_items_conf)
      # }
    ]

  default_tabs_sections["recent-updates"] =
    sections: [
      {
        id: "main"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          # section_item_title: "Today's Updates"
          expanded_on_init: true

        section_manager_options:
          query: ->
            # Hours limit sets the time delta from now to the oldest change
            # we want to catch in hours
            hours_limit =
              @getGlobalStateVar "hours-limit", ("" + (24 * 7)) # note section state vars values must be strings
            hours_limit = parseInt(hours_limit, 10)
            miliseconds_limit = hours_limit * 60 * 60 * 1000

            # Tracked field is the field we are querying to detect
            # updates
            tracked_field =
              @getGlobalStateVar "tracked-field", "updatedAt"

            # Custom query is a JSON-stringified object that will extend the
            # default query used to fetch updates
            custom_query =
              @getGlobalStateVar "custom-query", "{}"
            custom_query = JSON.parse custom_query

            query = {}

            addProjectIdToQuery(query)

            query[tracked_field] = {
              $gt: 
                new Date(Date.now() - miliseconds_limit)
            }

            query = _.extend query, custom_query

            sort = {}
            sort[tracked_field] = -1

            return APP.collections.Tasks.find(
              query,
              {sort: sort}
            ).fetch()
      }
    ]

  default_tabs_sections["awaiting-transfer"] =
    sections: [
      {
        id: "my-tasks"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "My Tasks Awaiting Transfer"
          expanded_on_init: true
          show_if_empty: true

        section_manager_options:
          query: ->
            query = {owner_id: Meteor.userId(), pending_owner_id: {$ne: null}}

            addProjectIdToQuery(query)

            return APP.collections.Tasks.find(
              query,
              {sort: {pending_owner_updated_at: -1}}
            ).fetch()
      }
      {
        id: "team-tasks"

        section_manager: "QuerySection"

        options:
          permitted_depth: 1
          section_item_title: "Team Tasks Awaiting Transfer"

        section_manager_options:
          query: ->
            query = {owner_id: {$ne: Meteor.userId()}, pending_owner_id: {$ne: null}}

            addProjectIdToQuery(query)

            return APP.collections.Tasks.find(
              query,
              {sort: {pending_owner_updated_at: -1}}
            ).fetch()
      }
    ]

  #
  # Default tabs definitions
  #
  _.extend project_page_module,
    default_tabs_definitions:
      [
        {
          id: "main"
          options:
            grid_control_options: gcOpsGen(default_tabs_sections["main"])
            removable: false
            activate_on_init: true
            tabTitleGenerator: "Main View"
        }
        {
          id: sub_tree_tab_id
          options:
            grid_control_options: gcOpsGen(default_tabs_sections[sub_tree_tab_id])
            removable: true
            activate_on_init: false
            tabTitleGenerator: "Sub Tree" # XXX need to have the root item task name
        }
        {
          id: "favorites"
          options:
            grid_control_options: gcOpsGen(default_tabs_sections["favorites"])
            removable: false
            activate_on_init: false
            tabTitleGenerator: "My Favorites"
        }
        {
          id: "tickets-queues"
          options:
            grid_control_options: gcOpsGen(default_tabs_sections["tickets-queues"])
            removable: false
            activate_on_init: false
            tabTitleGenerator: "Ticket Queues"
        }
        {
          id: "due-list"
          options:
            grid_control_options: _.extend(
              gcOpsGen(default_tabs_sections["due-list"]),
              {default_view_extra_fields: ["priv:follow_up"]}
            )
            removable: true
            activate_on_init: false
            tabTitleGenerator: (tab_id) ->
              # Note, the tab's titles produced below should
              # correspond to tab-switcher-dropdown.html
              sections_state = @getTabGridControlSectionsState(tab_id)

              if (owners_state = sections_state?.global?.owners)?
                owners_state = owners_state.split(",")

                if owners_state[0] == "*"
                  return "All members due list"

                if owners_state[0] == Meteor.userId()
                  return "My Due List"

                owners_display_names = _.map owners_state, (owner_id) =>
                  if (user_obj = Meteor.users.findOne(owner_id))?
                    return JustdoHelpers.displayName(user_obj)

                  return "Unknown"

                if owners_display_names.length == 1
                  return owners_display_names[0] + " Due List"
                else
                  return owners_display_names.join(", ") + " Due List"

              return "Due List"
        }
        {
          id: "recent-updates"
          options:
            grid_control_options: _.extend(
              gcOpsGen(default_tabs_sections["recent-updates"]),
              {default_view_extra_fields: ["updatedAt"]}
            )
            removable: true
            activate_on_init: false
            tabTitleGenerator: (tab_id) ->
              # Note, the tab's titles produced below should
              # correspond to tab-switcher-dropdown.html
              sections_state = @getTabGridControlSectionsState(tab_id)

              if (tracked_field = sections_state?.global?["tracked-field"])?
                if tracked_field == "state_updated_at"
                  return "Recently Completed"
                if tracked_field == "updatedAt"
                  return "Recently Updated"
                if tracked_field == "createdAt"
                  return "Recently Created"

              return "Recently updated"
        }
        {
          id: "awaiting-transfer"
          options:
            grid_control_options: gcOpsGen(default_tabs_sections["awaiting-transfer"])
            removable: true
            activate_on_init: false
            tabTitleGenerator: "Tasks Ownership Transfers"
        }
      ]
