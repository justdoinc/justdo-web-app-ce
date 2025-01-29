# Read about "both-code-executed" in /020-both/999-emit-both-code-executed.coffee
APP.once "both-code-executed", ->
  project_page_module = APP.modules.project_page

  # Shortcuts
  curProj = project_page_module.curProj

  base_grid_control_configuration =
    items_collection: APP.collections.Tasks
    allow_dynamic_row_height: true

    items_types_settings:
      # "default":
      #   metadataGenerator: (metadata, item, ext, index) ->
      #     if not (style = metadata.style)?
      #       style = metadata.style = {}

      #     style["background-color"] = JustdoColorGradient.getColorRgbString(item.priority or 0)

      "ticket-queue-caption":
        is_collection_item: true
        searchable: true
        getForcedItemFields: -> {_omit_seqId_comp: true, _omit_owner_control: true, priority: undefined}
        metadataGenerator: (metadata, item, ext, index) ->
          metadata.columns =
            0:
              editor: null
              colspan: "*"

      "member-direct-tasks-header":
        is_collection_item: false
        searchable: true
        metadataGenerator: (metadata, item, ext, index) ->
          metadata.columns =
            0:
              editor: null
              colspan: "*"

  _.extend project_page_module,
    generateGridControlOptionsForSections: (grid_control_conf) ->
      # Gets a sections array and returns an object with
      # grid control options based on our base_grid_control_configuration
      # and the provided sections
      #
      # Note that all the options in the returned object are
      # shallow copys, so you shouldn't change them without
      # creating a new object for them

      # The following is for legacy code, previously, this method received only
      # the sections array
      if _.isArray(grid_control_conf)
        grid_control_conf = {sections: grid_control_conf}

      return _.extend {}, base_grid_control_configuration, grid_control_conf