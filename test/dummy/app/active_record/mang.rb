# frozen_string_literal: true

class Mang < ActiveRecord::Base
  include DeviseJwtAuth::Concerns::User
end
