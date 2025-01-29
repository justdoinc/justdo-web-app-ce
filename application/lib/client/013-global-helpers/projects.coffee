_.extend APP.helpers,
  subscribeProjectMembersInfo: (project_id) ->
    # This logic is left for the justdo-guests package to maintain:
    #
    # See: initEncounteredUsersIdsTracker/initEncounteredUsersIdsPublicBasicUsersInfoFetcher
    #
    # project_members_ids = APP.projects.getProjectMembersIds(project_id, {include_removed_members: true})

    # if not _.isEmpty project_members_ids
    #   Meteor.subscribe "publicBasicUsersInfo", project_members_ids

    return