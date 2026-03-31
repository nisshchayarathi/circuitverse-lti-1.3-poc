# LTI 1.3 launches commonly return to the tool via a cross-site POST
# (response_mode=form_post). To keep the Rails session available on that POST
# (so we can read stored state/nonce), the session cookie should typically be:
#   SameSite=None; Secure
#
# This is POC-friendly guidance; in production you should review cookie settings
# based on your hosting/proxy/SSL termination setup.
Rails.application.config.session_store :cookie_store,
  key: "_lti_session",
  same_site: :none,
  secure: true
