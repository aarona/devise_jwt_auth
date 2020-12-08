# frozen_string_literal: true

module Overrides
  class ConfirmationsController < DeviseJwtAuth::ConfirmationsController
    def show
      @resource = resource_class.confirm_by_token(params[:confirmation_token])

      if @resource&.id
        update_refresh_token_cookie
        redirect_header_options = {
          account_confirmation_success: true,
          config: params[:config],
          override_proof: '(^^,)'
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
