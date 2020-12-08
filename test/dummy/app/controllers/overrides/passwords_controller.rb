# frozen_string_literal: true

module Overrides
  class PasswordsController < DeviseJwtAuth::PasswordsController
    OVERRIDE_PROOF = '(^^,)'

    # this is where users arrive after visiting the email confirmation link
    def edit
      @resource = resource_class.reset_password_by_token(
        reset_password_token: resource_params[:reset_password_token]
      )

      if @resource&.id
        # ensure that user is confirmed
        @resource.skip_confirmation! unless @resource.confirmed_at

        @resource.save!

        update_refresh_token_cookie
        redirect_header_options = {
          override_proof: OVERRIDE_PROOF,
          reset_password: true
        }
        redirect_headers = @resource.create_named_token_pair
                             .merge(redirect_header_options)
        redirect_to_link = DeviseJwtAuth::Url.generate(params[:redirect_url], redirect_headers)
        redirect_to redirect_to_link
      else
        raise ActionController::RoutingError, 'Not Found'
      end
    end
  end
end
