project_page_module = APP.modules.project_page

_.extend project_page_module,
  _getOpShortcuts: (op_name) ->
    # Returns an array with both the main and alternative key-shortcuts
    # of op_name; null if there are no key-shortcuts are defined for
    # this op
    op = @ops[op_name]

    shortcuts = []
    if op.alternative_shortcuts?
      shortcuts = op.alternative_shortcuts.slice() # make a copy

    if (keyboard_shortcut = op.keyboard_shortcut)?
      if _.isFunction keyboard_shortcut
        keyboard_shortcut = keyboard_shortcut()
      shortcuts.push keyboard_shortcut

    if not _.isEmpty shortcuts
      return shortcuts
    else
      return null

  loadKeyboardShortcuts: ->
    for op_name of @ops
      do (op_name) =>
        if (shortcuts = @_getOpShortcuts(op_name))?
          Mousetrap.bind shortcuts, =>
            @performOp(op_name)

  unloadKeyboardShortcuts: ->
    for op_name of @ops
      do (op_name) =>
        if (shortcuts = @_getOpShortcuts(op_name))?
          Mousetrap.unbind shortcuts

  humanReadableShortcutSeq_replace_map:
    "\\+": " "
    "plus": "+"
    "alt": "Alt"
    "up": "▲"
    "down": "▼"
    "left": "◄"
    "right": "►"

  humanReadableShortcutSeq: (shortcut_seq) ->
    # Gets Mousetrap keyboard sequence returns in human
    # readable format

    map = @humanReadableShortcutSeq_replace_map

    for regexp, replacement of map
      shortcut_seq = shortcut_seq.toUpperCase().replace RegExp(regexp, "gi"), replacement

    return shortcut_seq