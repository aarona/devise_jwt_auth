# frozen_string_literal: true

require 'test_helper'

class DeviseJwtAuth::BlacklistTest < ActiveSupport::TestCase
  describe Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION do
    test 'should include :tokens' do
      assert Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION.include?(:tokens)
    end
  end
end
