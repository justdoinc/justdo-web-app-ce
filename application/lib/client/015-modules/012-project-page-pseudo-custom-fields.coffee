project_page_module = APP.modules.project_page

pseudo_custom_fields = {}

pseudo_custom_fields_dep = new Tracker.Dependency()

_.extend project_page_module,
  getPseudoCustomFields: ->
    pseudo_custom_fields_dep.depend()

    return pseudo_custom_fields

  setupPseudoCustomField: (custom_field_id, custom_field_object) ->
    # Setup a new pseudo custom field (a custom field without mapping to a real field).
    #
    # * CANCELED - custom_field_object.field_id will be forced to 'pseudo__#{custom_field_id}'
    #   don't attempt prefixing, it is a bit too complex to do well, and doesn't worth the 
    #   effort.
    # * CANCELED - grid_editable_column will be forced to false - no reason to not let plugins
    #   developer to use this to set custom fields that aren't written to the project doc under
    #   custom fields nor presented to the user in a way he can tamper with them.
    #
    # Both custom_field_id and custom_field_obj have to comply with
    # custom_field_definition_schema under: 
    # grid-control-custom-fields/lib/both/grid-control-custom-fields/grid-control-custom-fields.coffee
    # (custom_field_id need to comply with the definition for field_id) .
    #
    # Note regarding performance:
    # 
    # Since the reactivity framework (Tracker) is used to put the changes to pseudo_custom_fields
    # into effect, we don't worry about cases where loops are performing multiple calls to
    # setupPseudoCustomField(). Since invalidation for all the calls will happen only once,
    # hence performance wise (except some minor points) complexity is the same.

    custom_field_object = _.extend {}, custom_field_object # shallow copy

    _.extend custom_field_object,
      field_id: custom_field_id

    pseudo_custom_fields[custom_field_id] = custom_field_object

    pseudo_custom_fields_dep.changed()

    return

  removeFieldsFromCurrentMuxGridControlViews: (fields_to_remove) ->
    # If we got a multiplexer running, remove fields_to_remove from all the ready views. 
    if (gcm = APP.modules.project_page.getGridControlMux())?
      for tab_id, tab of gcm.getAllTabsNonReactive()
        if tab.state == "ready"
          view = _.filter tab.grid_control.getView(), (column) ->
            return not (column.field in fields_to_remove)
          
          tab.grid_control.setView view

    return

  removePseudoCustomFields: (fields_to_remove) ->
    if _.isString fields_to_remove
      fields_to_remove = [fields_to_remove]
    
    for custom_field_id in fields_to_remove
      delete pseudo_custom_fields[custom_field_id]

    @removeFieldsFromCurrentMuxGridControlViews(fields_to_remove)

    pseudo_custom_fields_dep.changed()

    return

  extendSchemaFieldWithPseudoField: (field_id, custom_field_object) ->
    return @replaceSchemaFieldWithPseudoField(field_id, custom_field_object, {use_collection_schema_definition_as_base: true})

  replaceSchemaFieldWithPseudoField: (field_id, custom_field_object, options) ->
    # IMPORTANT NOTE If field_type or label weren't provided in custom_field_object, we'll derive
    # them from the original schema (critical to maintain proper Activity Logs (Activity tab in
    # the Task Pane)).
    #
    # Note if called more than once for the same field, say with {a: 1, b: 1}, {b: 2, c: 3}, without calling
    # removeSchemaFieldModification in-between the result will be as if it was called once with {a: 1, b: 2, c: 3}.
    #
    # If options.use_collection_schema_definition_as_base is set to true
    # the existing settings for field_id in the schema will be used as the basis for the custom_field_object
    # i.e for every field in the schema that isn't set by custom_field_object we will use the schema's
    # field - if that option isn't set we ignore all the schema fields *except* of label and type (see IMPORTANT NOTE above)

    if not (schema_def = JustdoHelpers.getCollectionSchemaForField(APP.collections.Tasks, field_id))
      throw new Meteor.Error("unknown-field-id", "The provided field_id #{field_id} isn't in the Tasks schema")

    existing_modification = pseudo_custom_fields[field_id] or {}

    custom_field_object = _.extend {}, existing_modification, custom_field_object

    if "label" not of custom_field_object
      custom_field_object.label = schema_def.label

    if "field_type" not of custom_field_object
      custom_field_object.field_type = GridControlCustomFields.getFieldTypeForJSType(schema_def.type)

    if options?.use_collection_schema_definition_as_base is true
      custom_field_object = _.extend {}, _.omit(schema_def, "type", "optional"), custom_field_object

    if custom_field_object.grid_visible_column is false
      @removeFieldsFromCurrentMuxGridControlViews([field_id])

    @setupPseudoCustomField(field_id, custom_field_object)

    return

  removeSchemaFieldReplacement: (field_id) ->
    # This is merely a readability feature.
    @removePseudoCustomFields(field_id)

    return
