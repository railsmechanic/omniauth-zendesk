require 'zendesk_api'

module OmniAuth
  module Strategies
    class Zendesk
      include OmniAuth::Strategy

      option :site, nil
      option :params, { username: 'email', password: 'password' }
      option :on_failed_registration, nil

      uid  { identity.email }
      info {
        {
          name:         identity.name,
          email:        identity.email,
          role:         identity.role,
          time_zone:    identity.time_zone,
          description:  identity.notes,
          image:        identity.photo.respond_to?(:thumbnails) ? identity.photo.thumbnails.first.content_url : nil,
          phone:        identity.phone,
          site:         site
        }
      }
      credentials { { token: username, secret: password } }
      extra { { raw_info: identity } }

      def request_phase
        if site && username && password
          r = Rack::Response.new
          r.redirect(callback_path, 307)
          r.finish
        else
          OmniAuth::Form.build(title: (options[:title] || "Zendesk Authentication"), url: callback_path) do |f|
            f.text_field 'Username', options.params.username
            f.password_field 'Password', options.params.password
          end.to_response
        end
      end

      def callback_phase
        return fail!(:invalid_credentials) if not identity or identity.email == 'invalid@example.com'
        super
      end

      def identity
        return unless site && username && password
        client = ZendeskAPI::Client.new do |c|
          c.url = "#{site}/api/v2"
          c.username = username
          c.password = password
        end
        @identity ||= client.current_user
      end

      protected

      def site
        options.site
      end

      def username
        request.params[options.params.username]
      end

      def password
        request.params[options.params.password]
      end
    end
  end
end
