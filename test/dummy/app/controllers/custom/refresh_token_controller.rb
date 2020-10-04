# frozen_string_literal: true

module Custom
  class RefreshTokenController < DeviseJwtAuth::RefreshTokenController
    def show
      super do |resource|
        @refresh_token_block_called = true unless resource.nil?
      end
    end

    def refresh_token_block_called?
      @refresh_token_block_called == true
    end

    protected

    def render_refresh_token_success
      render json: { custom: 'foo' }
    end
  end
end
