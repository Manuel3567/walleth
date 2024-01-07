data "auth0_client" "management_client" {
  name = "Auth0 Account Management API Management Client"
}


resource "auth0_connection" "user_password_database" {
  name     = "Username-Password-Authentication"
  strategy = "auth0"
  options {
    password_policy        = "excellent"
    brute_force_protection = true
    mfa {
      active                 = true
      return_enroll_settings = true
    }
  }
}
resource "auth0_action" "add_email_to_access_token" {
  name    = "Add email to access token"
  runtime = "node18"
  deploy  = true
  code    = <<-EOT
  /**
   * Handler that will be called during the execution of a PostLogin flow.
   *
   * @param {Event} event - Details about the user and the context in which they are logging in.
   * @param {PostLoginAPI} api - Interface whose methods can be used to change the behavior of the login.
   */
  exports.onExecutePostLogin = async (event, api) => {
    //const namespace = '${var.api_url}';
    
    if (event.authorization) {
        //api.accessToken.setCustomClaim(namespace + '/email', event.user.email);
        api.accessToken.setCustomClaim('backend/email', event.user.email);

    }
  };
  EOT

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }

}

resource "auth0_trigger_actions" "login_flow" {
  trigger = "post-login"

  actions {
    id           = auth0_action.add_email_to_access_token.id
    display_name = auth0_action.add_email_to_access_token.name
  }
}



resource "auth0_client" "walleth" {
  name                 = "Application - Walleth"
  app_type             = "spa"
  custom_login_page_on = true
  is_first_party       = true
  #is_token_endpoint_ip_header_trusted = true # only set if not first party
  oidc_conformant = true
  # TODO: abstract
  callbacks           = [var.auth0_redirect_uri]
  allowed_origins     = [var.app_url]
  allowed_logout_urls = [var.app_url]
  web_origins         = [var.app_url]
  grant_types = [
    "authorization_code",
    "http://auth0.com/oauth/grant-type/password-realm",
    "implicit",
    "refresh_token"
  ]

  jwt_configuration {
    lifetime_in_seconds = 300
    secret_encoded      = true
    alg                 = "RS256"
    scopes = {
      foo = "bar"
    }
  }

  refresh_token {
    leeway          = 0
    token_lifetime  = 2592000
    rotation_type   = "rotating"
    expiration_type = "expiring"
  }


}

resource "auth0_resource_server" "walleth_api" {
  name        = "API - Walleth"
  identifier  = var.api_url
  signing_alg = "RS256"

  allow_offline_access                            = true
  token_lifetime                                  = 8600
  skip_consent_for_verifiable_first_party_clients = true
}

resource "auth0_connection_clients" "user_password_client_connection" {
  connection_id = auth0_connection.user_password_database.id
  enabled_clients = [
    auth0_client.walleth.id,
    data.auth0_client.management_client.id
  ]
}


#output auth0_mgmt_client {
#  value       = data.auth0_client.management_client.id
#}

output "auth0_app_client_id" {
  value = auth0_client.walleth.id
}
