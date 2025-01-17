# Following the pentest performed September 2022 we decided to stop using
# Google Analytics for the lack of value it gives us from one hand, and the
# noise it created for the pentesting in the other hand.

# If in the future you'll decide to re-enable it, read again the report, which is available
# here: https://drive.google.com/drive/folders/1tTAwCh3AcZi_022hZUQvjgejHTNnc9ta?usp=sharing

# Specifically, I think that sending the user's id under: ajs_user_id is wrong, and should be
# avoided anyways in the future. (See in the report under: "Cookie Faults")

# further, I think we shouldn't pass the user's email under ajs_user_traits.
# (See in the report under: "Sensitive Information Stored in Local Storage")

# Daniel C. 2022-09-21

# 2023-05-24 UPDATE: Moved to Server side, see: 004-head-injections.coffee

# APP.once "env-vars-ready", (env) ->
#   tracking_id = env.GA_TRACKING_ID
#   if tracking_id? and tracking_id != "" # Google analytics tracking id
#     if not window.InitAnalytics?
#       throw new Error "Analytics blocked by adblock"
#     else
#       window.InitAnalytics # Provided by justdoinc:analytics see explanation there for why it is binded to window.
#         "autorun": false # Disable auto route change logging - logging every route change triggers event on every task activation, redundant and might be a privacy concern
#         "Google Analytics":
#           "trackingId": tracking_id
#   else
#     APP.logger.debug "APP: env variable GA_TRACKING_ID undefined or empty, analytics disabled"