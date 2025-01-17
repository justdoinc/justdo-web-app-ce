if Meteor.isServer
  JustdoEmails.options.logo_path = process.env?.LANDING_APP_ROOT_URL + "/layout/logos/justdo_logo_for_emails.png"