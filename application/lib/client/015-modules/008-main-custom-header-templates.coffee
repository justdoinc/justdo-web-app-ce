main_module = APP.modules.main

main_module._custom_header_templates = new ReactiveDict()

_.extend main_module,
  setCustomHeaderTemplate: (position_id, template_name) ->
    main_module._custom_header_templates.set(position_id, template_name)

    return

  getCustomHeaderTemplate: (position_id) ->
    return main_module._custom_header_templates.get(position_id)

  unsetCustomHeaderTemplate: (position_id) ->
    main_module._custom_header_templates.delete(position_id)

    return