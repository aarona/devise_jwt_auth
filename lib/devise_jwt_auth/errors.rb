# frozen_string_literal: true

module DeviseJwtAuth
  module Errors
    class NoResourceDefinedError < StandardError; end
    class InvalidModel < StandardError; end
  end
end
