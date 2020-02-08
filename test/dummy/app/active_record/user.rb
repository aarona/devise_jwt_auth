# frozen_string_literal: true

class User < ActiveRecord::Base
  include DeviseJwtAuth::Concerns::User
  include FavoriteColor
end
