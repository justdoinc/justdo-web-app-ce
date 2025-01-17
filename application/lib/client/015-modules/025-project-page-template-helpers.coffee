project_page_module = APP.modules.project_page

# Shortcuts
helpers = project_page_module.helpers
curProj = helpers.curProj

Meteor._ensure project_page_module, "template_helpers"

isUserIdEnrolled = (user_id) ->
  return JustdoHelpers.getUserDocById(user_id, {get_docs_by_reference: true})?.enrolled_member

_.extend project_page_module.template_helpers,
    #
    # Project details
    #
    is_project_admin: -> curProj()?.isAdmin()

    is_project_guest: ->
      return curProj()?.isGuest()

    is_current_user: (member_id) ->
      return member_id == Meteor.userId()

    allow_member_remove: (member_id) ->
      if curProj()?.isAdmin()
        return true

      if member_id == Meteor.userId()
        return true

      return false

    allow_show_member_dropdown_settings: (member_id) ->
      if curProj()?.isAdmin() or member_id == Meteor.userId()
        return true

      return false

    allow_member_edit_enrollment_pending_member: (member_id) ->
      # In the past we limited the ability to open the enrollment editor
      # now the the enrollment editor let's *all* the users to: view (not edit) the invitee email + display name
      # and resend invitation email
      return true

    project_members_count: -> curProj().membersCount()
    project_all_members: -> helpers.augment_members_field(curProj().getMembers())
    project_all_members_except_me: (filter) ->
      project_all_members_except_me = helpers.augment_members_field(_.filter(curProj()?.getMembers(), (member) -> member.user_id != Meteor.userId()))

      if filter?
        project_all_members_except_me = JustdoHelpers.filterUsersDocsArray(project_all_members_except_me, filter)

      return project_all_members_except_me

    project_all_members_sorted_by_first_name: (filter) ->
      return JustdoHelpers.sortUsersDocsArrayByDisplayName(project_page_module.template_helpers.project_all_members(filter))

    project_all_members_except_me_sorted_by_first_name: (filter) ->
      return JustdoHelpers.sortUsersDocsArrayByDisplayName(project_page_module.template_helpers.project_all_members_except_me(filter))

    project_non_enrolled_members: (filter) ->
      project_non_enrolled_members = helpers.augment_members_field(_.filter(curProj().getMembers(), (member) -> not isUserIdEnrolled(member.user_id) and not member.is_guest))

      if filter?
        project_non_enrolled_members = JustdoHelpers.filterUsersDocsArray(project_non_enrolled_members, filter)

      return project_non_enrolled_members

    project_non_enrolled_members_sorted_by_first_name: (filter) ->
      return JustdoHelpers.sortUsersDocsArrayByDisplayName(project_page_module.template_helpers.project_non_enrolled_members(filter))

    project_non_enrolled_guests: (filter) ->
      project_non_enrolled_guests = helpers.augment_members_field(_.filter(curProj().getMembers(), (member) -> not isUserIdEnrolled(member.user_id) and member.is_guest))

      if filter?
        project_non_enrolled_guests = JustdoHelpers.filterUsersDocsArray(project_non_enrolled_guests, filter)

      return project_non_enrolled_guests

    project_non_enrolled_guests_sorted_by_first_name: (filter) ->
      return JustdoHelpers.sortUsersDocsArrayByDisplayName(project_page_module.template_helpers.project_non_enrolled_guests(filter))

    project_regular_members: (filter) ->
      project_regular_members = helpers.augment_members_field(curProj().getNonAdminsNonGuests(false))

      if filter?
        project_regular_members = JustdoHelpers.filterUsersDocsArray(project_regular_members, filter)

      return project_regular_members

    project_enrolled_regular_members_sorted_by_first_name: (filter) ->
      members = project_page_module.template_helpers.project_regular_members(filter)

      return JustdoHelpers.sortUsersDocsArrayByDisplayName(members)

    project_guests: (filter) ->
      project_guests = helpers.augment_members_field(curProj().getGuests(false))

      if filter?
        project_guests = JustdoHelpers.filterUsersDocsArray(project_guests, filter)

      return project_guests

    project_enrolled_guests_sorted_by_first_name: (filter) ->
      guests = project_page_module.template_helpers.project_guests(filter)

      return JustdoHelpers.sortUsersDocsArrayByDisplayName(guests)

    project_admins: (filter) ->
      project_admins = helpers.augment_members_field(curProj().getAdmins(false))

      if filter?
        project_admins = JustdoHelpers.filterUsersDocsArray(project_admins, filter)

      return project_admins

    project_enrolled_admins_sorted_by_first_name: (filter) ->
      members = project_page_module.template_helpers.project_admins(filter)

      return JustdoHelpers.sortUsersDocsArrayByDisplayName(members)

    project_is_untitled: -> curProj()?.isUntitled()
    project_title: -> curProj()?.getProjectDoc({fields: {title: 1}})?.title

    isSubscribedToDailyEmail: -> curProj()?.isSubscribedToDailyEmail()

    isSubscribedToEmailNotifications: -> curProj()?.isSubscribedToEmailNotifications()

    getProjectConfigurationSetting: (setting) ->
      return curProj().getProjectConfigurationSetting(setting)

    #
    # Grid control details
    #
    grid_ready: -> project_page_module.gridReady()

    active_item_obj: (fields, inverse) ->
      # Field is a comma separated list of fields to include in the returned object
      # if inverse is true, we will return all the fields other than those specified
      #
      # If fields is undefined, all fields will be returned (might cause many undesired
      # invalidations, so should be avoided in computations)
      if Tracker.currentComputation? and not fields?
        project_page_module.logger.warn "You should avoid using {{active_item_obj}} in reactive computation without limiting the fields you need"

      if not _.isBoolean(inverse)
        # If isn't boolean, we assume user didn't provide it
        inverse = false

      if not fields?
        fields = {}
      else
        _fields = {}

        inclusive_val = if inverse then 0 else 1
        for field in fields.split(",")
          _fields[field] = inclusive_val

        fields = _fields

      return project_page_module.activeItemObj(fields)

    userEmail: (user) ->
      return JustdoHelpers.getUserMainEmail(user)

  # Note, more helpers are defined in the justdoinc:justdo-task-pane package

# template_helpers is a sub-set of helpers

# Make all template helpers project_page_module helpers
_.extend helpers, project_page_module.template_helpers
