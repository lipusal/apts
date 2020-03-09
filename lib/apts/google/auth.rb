# frozen_string_literal: true

require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'google/apis/drive_v3'

module Apts
  module Google
    class Auth
      OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
      SCOPE = ::Google::Apis::DriveV3::AUTH_DRIVE_FILE
      CLIENT_SECRETS_PATH = 'client_secrets.json'
      TOKENS_PATH = 'tokens.yaml'
      APPLICATION_NAME = 'Apartments Scraper'

      def authenticate
        client_id = ::Google::Auth::ClientId.from_file(CLIENT_SECRETS_PATH)
        token_store = ::Google::Auth::Stores::FileTokenStore.new(file: TOKENS_PATH)
        authorizer = ::Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
        user_id = ENV['GOOGLE_USER_ID']

        credentials = authorizer.get_credentials(user_id)
        if credentials.nil?
          url = authorizer.get_authorization_url(base_url: OOB_URI)
          puts "Open #{url} in your browser and enter the resulting code:"
          code = gets
          credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
        end

        credentials
      end
    end
  end
end
