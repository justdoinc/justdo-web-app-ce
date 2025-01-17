# I put the following code here and not under 005-packages-configuration
# since I want to obscure the existence of this feature. There isn't a security
# issue with it, just to be on the safe side.

# Zendesk configurations that will be set immediately after Zendesk embed
# code in <head> . Provided with the html payload. 

JustdoZendesk?.zendesk_additional_head_configurations = """
  <script>
    zE(function() {
      zE.setLocale('en-US');
      zE.hide();
      zE.setHelpCenterSuggestions({ labels: ['web-app'] })
    });
  </script>
"""