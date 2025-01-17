project_page_module = APP.modules.project_page

_.extend project_page_module,
  # Stores the project page operations
  ops: {}

  performOp: (op_name) ->
    project_page_module.logger.debug "Perform grid-op: #{op_name}"

    op = project_page_module.ops[op_name]

    requirements = project_page_module.getUnfulfilledOpReq(op_name)

    if _.isEmpty requirements
      op()
    else
      project_page_module.logger.warn "can't perform operation, unfulfilled requirements #{JSON.stringify(requirements)}"

  getUnfulfilledOpReq: (op_name) ->
    requirements = project_page_module._opreqGridInitialized()

    if _.isEmpty requirements
      # Grid must be initialized to perform ops, prereq() can assume its existence
      # therefore, we must not call prereq if grid isn't init.
      op = project_page_module.ops[op_name]
      prereq = op.prereq

      requirements = prereq()

    return requirements

  setNullaryOperation: (op_name, settings) ->
    # add a method to ops object with the nullary op op_name.
    # add the settings properties as properties of that method function
    # object.
    self = @
    @ops[op_name] = settings.op
    _.extend @ops[op_name], settings

    if (template = settings.template)?
      if _.isObject template
        name_dashed = APP.helpers.lowerCamelTo "-", op_name
        name_underscored = APP.helpers.lowerCamelTo "_", op_name

        template_name = "project_operations_#{name_underscored}"
        Template.__checkName template_name

        btn_title = settings.human_description
        btn_title_i18n = settings.human_description_i18n

        Template[template_name] =
          new Template "Template.#{template_name}", ->
            view = this

            btnClassAttr = ->
              class_attr = []

              class_attr.push "btn-grid-operations d-flex align-items-center project-operations-button "

              class_attr.push(Blaze.If ->
                Spacebars.call view.lookup('unfulfilledPrereq')
              , -> 'disabled')

              class_attr.push(Blaze.If ->
                Spacebars.call view.lookup('opsLockIsOn')
              , -> 'ops-lock')

              class_attr.push(Blaze.If ->
                Spacebars.call view.lookup('gridNotInit')
              , -> 'grid-not-init')

              class_attr.push(Blaze.If ->
                Spacebars.call view.lookup('gridNotReady')
              , -> 'grid-not-ready')

              return class_attr

            btnTitleAttr = ->
              title_attr = []
              
              title = APP.justdo_i18n.getI18nTextOrFallback {fallback_text: btn_title, i18n_key: btn_title_i18n}
              title_attr.push title

              if settings.keyboard_shortcut?
                title_attr.push " "
                title_attr.push HTML.CharRef
                  html: "&mdash;"
                  str: "—"
                title_attr.push " "
                title_attr.push(Blaze.If ->
                  Spacebars.call view.lookup('humanReadableShortcutSeq')
                , -> [
                        " ("
                        Blaze.View('lookup:humanReadableShortcutSeq', ->
                          Spacebars.mustache view.lookup('humanReadableShortcutSeq')
                        )
                        ")"
                     ]
                
                )

              title_attr.push(Blaze.If ->
                Spacebars.call view.lookup('onePrereqMessage')
              , -> [
                      "\n"
                      Blaze.View('lookup:onePrereqMessage', ->
                        Spacebars.mustache view.lookup('onePrereqMessage')
                      )
                   ]
              )

              return title_attr

            HTML.DIV {
              id: name_dashed
              class: btnClassAttr
              title: btnTitleAttr
            }

        template_events = {}

        template_events["click ##{name_dashed}"] = =>
          @performOp(op_name)

        Template[template_name].events template_events

        if template.font_awesome_icon?
          template.custom_icon_html = "<i class=\"fa fa-" + template.font_awesome_icon + "\"></i>"

        Template[template_name].onRendered ->
          # We are using onRendered to set the inner html of the icon, since we found out that returning
          # HTML.Raw in the 'new Template' above, is not working well for SVG html, which isn't rendered
          # if that approach is used.
          if _.isFunction template.custom_icon_html
            @autorun =>
              $(@firstNode).html(template.custom_icon_html())
          else
            $(@firstNode).html(template.custom_icon_html)

          return

        # When the template is created, track changes to prereq and
        # hold them in a reactive var that is used by all the template
        # methods that follows prereq.
        # We do that to call the operation prereq only once on every
        # invalidation (without this we used to call prereq > 5 times)
        # note, that it's required since prereq functions might be quite
        # with > O(1) complexity.
        # In addition, by using a reactive var we gain invalidation of
        # template only when prereq really changed.
        prereq_comp = null
        prereq_reactive_var = new ReactiveVar {}, (a, b) -> JSON.stringify(a) == JSON.stringify(b) # Invalidate if really changed
        Template[template_name].onCreated ->
          prereq_comp = Tracker.autorun ->
            prereq_reactive_var.set project_page_module.getUnfulfilledOpReq(op_name)

        # Destroy the tracker when template destroyed
        Template[template_name].onDestroyed ->
          if prereq_comp?
            prereq_comp.stop()
          prereq_reactive_var.set {}

        prereq = ->
          prereq_reactive_var.get()

        prereqWithoutSpecialPrereq = ->
          requirements = prereq()

          delete requirements.ops_locked
          delete requirements.grid_not_init
          delete requirements.grid_not_ready

          return requirements

        helpers =
          opsLockIsOn: ->
            # We give grid control's ops_locked special
            # consideration as we style it differently
            # to avoid the disabled style of ops button
            # from showing often, but only when more
            # "stronger" unfulfilled prereqs are present.
            prereq().ops_locked?

          gridNotReady: ->
            prereq().grid_not_ready?

          gridNotInit: ->
            prereq().grid_not_init?

          unfulfilledPrereq: -> not _.isEmpty prereqWithoutSpecialPrereq()

          onePrereqMessage: ->
              # We don't call it firstPrereqMessage, as there's no order
              if helpers.unfulfilledPrereq()
                requirements = prereqWithoutSpecialPrereq()

                return _.values(requirements)[0]

              return null
          
          humanReadableShortcutSeq: ->
            if not (keyboard_shortcut = settings.keyboard_shortcut)?
              return
            
            if _.isFunction keyboard_shortcut
              keyboard_shortcut = keyboard_shortcut()

            return self.humanReadableShortcutSeq keyboard_shortcut

        # Testing
        # Tracker.autorun ->
        #   console.log op_name
        #   for helper_name of helpers
        #     console.log helper_name, helpers[helper_name]()

        Template[template_name].helpers helpers
