Meteor.publish null, ->
  if not @userId?
    @ready()

    return

  APP.accounts.basicUserInfoPublicationHandler(@, {
    users_ids: [@userId]
    public_basic_user_info_cursor_options: {
      additional_fields: {
        # profile: 1
        # emails: 1 # These two are published automatically by accounts-base/accounts_server.js see Ap._initServerPublications
        createdAt: 1

        "justdo_chat.email_notifications": 1

        "justdo_projects.post_reg_init": 1
        "justdo_projects.daily_email_projects_array": 1
        "justdo_projects.prevent_notifications_for": 1

        "promoters.is_promoter": 1
        "promoters.is_approved": 1
        "promoters.referring_campaign_id": 1
        "promoters.read_campaign_messages": 1

        "promoters.rtry": 1
        "promoters.rtryc": 1
        "promoters.rtrial": 1
        "promoters.ui": 1

        "promoters.promoter_description": 1

        "justdo_user_active_position.hide_user_active_position": 1
      },
      include_profile_fields: false
    }
  })

  return
