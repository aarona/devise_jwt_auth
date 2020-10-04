# frozen_string_literal: true

require 'jwt'

module DeviseJwtAuth::Concerns::User
  extend ActiveSupport::Concern

  included do
    # Hack to check if devise is already enabled
    if method_defined?(:devise_modules)
      devise_modules.delete(:omniauthable)
    else
      devise :database_authenticatable, :registerable,
             :recoverable, :validatable, :confirmable
    end

    if const_defined?('ActiveRecord') && ancestors.include?(ActiveRecord::Base)
      include DeviseJwtAuth::Concerns::ActiveRecordSupport
    end

    if const_defined?('Mongoid') && ancestors.include?(Mongoid::Document)
      include DeviseJwtAuth::Concerns::MongoidSupport
    end

    include DeviseJwtAuth::Concerns::UserOmniauthCallbacks if DeviseJwtAuth.default_callbacks

    # don't use default devise email validation
    def email_required?
      false
    end

    def email_changed?
      false
    end

    def will_save_change_to_email?
      false
    end

    if DeviseJwtAuth.send_confirmation_email && devise_modules.include?(:confirmable)
      include DeviseJwtAuth::Concerns::ConfirmableSupport
    end

    def password_required?
      return false unless provider == 'email'

      super
    end

    # override devise method to include additional info as opts hash
    def send_confirmation_instructions(opts = {})
      generate_confirmation_token! unless @raw_confirmation_token

      # fall back to "default" config name
      opts[:client_config] ||= 'default'
      opts[:to] = unconfirmed_email if pending_reconfirmation?
      opts[:redirect_url] ||= DeviseJwtAuth.default_confirm_success_url

      send_devise_notification(:confirmation_instructions, @raw_confirmation_token, opts)
    end

    # override devise method to include additional info as opts hash
    def send_reset_password_instructions(opts = {})
      token = set_reset_password_token

      # fall back to "default" config name
      opts[:client_config] ||= 'default'

      send_devise_notification(:reset_password_instructions, token, opts)
      token
    end

    # override devise method to include additional info as opts hash
    def send_unlock_instructions(opts = {})
      raw, enc = Devise.token_generator.generate(self.class, :unlock_token)
      self.unlock_token = enc
      save(validate: false)

      # fall back to "default" config name
      opts[:client_config] ||= 'default'

      send_devise_notification(:unlock_instructions, raw, opts)
      raw
    end

    def create_token(token_options = {})
      DeviseJwtAuth::TokenFactory.create_access_token({ sub: uid }.merge(token_options))
    end

    def create_refresh_token(token_options = {})
      DeviseJwtAuth::TokenFactory.create_refresh_token({ sub: uid }.merge(token_options))
    end
  end

  # Returns a hash that you can merge into a json response or in the case of
  # testing, merge it into a testing request.
  def create_named_token_pair(token_options = {})
    { DeviseJwtAuth.access_token_name.to_sym => create_token(token_options) }
  end

  # this must be done from the controller so that additional params
  # can be passed on from the client
  def send_confirmation_notification?
    false
  end

  def build_auth_url(base_url, args)
    args[:uid]    = uid
    args[:expiry] = tokens[args[:client_id]]['expiry']

    DeviseJwtAuth::Url.generate(base_url, args)
  end

  def extend_batch_buffer(token, client)
    tokens[client]['updated_at'] = Time.zone.now
    update_auth_header(token, client)
  end

  def confirmed?
    devise_modules.exclude?(:confirmable) || super
  end

  def token_validation_response
    as_json(except: %i[tokens created_at updated_at])
  end
end
