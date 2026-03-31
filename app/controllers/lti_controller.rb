require "json"
require "net/http"
require "uri"
require "openssl"
require "base64"

class LtiController < ApplicationController
  DUMMY_RSA_KEY = OpenSSL::PKey::RSA.generate(2048)
  DUMMY_JWKS = {
    keys: [
      {
        kty: "RSA",
        kid: "dummy-rsa-key",
        use: "sig",
        alg: "RS256",
        n: Base64.urlsafe_encode64(DUMMY_RSA_KEY.n.to_s(2), padding: false),
        e: Base64.urlsafe_encode64(DUMMY_RSA_KEY.e.to_s(2), padding: false)
      }
    ]
  }.freeze

  skip_before_action :verify_authenticity_token
  after_action :allow_iframe_embedding

  # GET /jwks.json
  def jwks
    render json: DUMMY_JWKS
  end

  # POST /lti/oidc/login
  def login
    # Relaxed param handling for POC
    iss = params[:iss].presence || "https://saltire.lti.app"
    login_hint = params[:login_hint].presence || "dummy-login-hint"
    target_link_uri = "https://e889-223-225-110-114.ngrok-free.app/lti/oidc/callback"
    lti_message_hint = params[:lti_message_hint]

    client_id = params[:client_id].presence || ENV["LTI_CLIENT_ID"] || "dummy-client-id"

    state = SecureRandom.hex(32)
    nonce = SecureRandom.hex(32)

    session[:lti_oidc_state] = state
    session[:lti_oidc_nonce] = nonce

    authorization_endpoint = resolve_authorization_endpoint(iss)

    auth_params = {
      scope: "openid",
      response_type: "id_token",
      response_mode: "form_post",
      prompt: "none",
      client_id: client_id,
      redirect_uri: target_link_uri,
      login_hint: login_hint,
      state: state,
      nonce: nonce
    }

    auth_params[:lti_message_hint] = lti_message_hint if lti_message_hint.present?

    redirect_to build_url(authorization_endpoint, auth_params), allow_other_host: true
  end

  # POST /lti/oidc/callback
  def callback
    id_token = params[:id_token].to_s
    returned_state = params[:state].to_s

    return render plain: "Missing id_token", status: :bad_request if id_token.blank?

    expected_state = session.delete(:lti_oidc_state).to_s
    expected_nonce = session.delete(:lti_oidc_nonce).to_s

    payload, _header = JWT.decode(id_token, nil, false)

    @claims = payload
    @state_ok = expected_state.present? && safe_compare(returned_state, expected_state)
    @nonce_ok = expected_nonce.present? && payload["nonce"].to_s == expected_nonce

  rescue JWT::DecodeError => e
    render plain: "JWT decode error: #{e.message}", status: :unprocessable_entity
  end

  private

  def allow_iframe_embedding
    response.headers.delete("X-Frame-Options")
  end

  def resolve_authorization_endpoint(iss)
    return ENV["LTI_AUTH_ENDPOINT"] if ENV["LTI_AUTH_ENDPOINT"].present?

    discovery = oidc_discovery(iss)
    discovery.fetch("authorization_endpoint")
  rescue StandardError => e
    Rails.logger.warn("OIDC discovery failed: #{e.class}: #{e.message}")
    iss
  end

  def oidc_discovery(iss)
    base = iss.to_s
    base += "/" unless base.end_with?("/")

    url = URI.join(base, ".well-known/openid-configuration")

    response = Net::HTTP.start(
      url.host,
      url.port,
      use_ssl: url.scheme == "https",
      open_timeout: 3,
      read_timeout: 3
    ) do |http|
      http.get(url.request_uri, { "Accept" => "application/json" })
    end

    raise "Discovery request failed (#{response.code})" unless response.is_a?(Net::HTTPSuccess)

    JSON.parse(response.body)
  end

  def build_url(base, params_hash)
    uri = URI.parse(base)
    existing = Rack::Utils.parse_nested_query(uri.query)
    uri.query = Rack::Utils.build_query(existing.merge(params_hash))
    uri.to_s
  end

  def safe_compare(a, b)
    return false if a.blank? || b.blank? || a.bytesize != b.bytesize

    ActiveSupport::SecurityUtils.secure_compare(a, b)
  end
end