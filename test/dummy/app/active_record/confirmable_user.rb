# frozen_string_literal: true

class ConfirmableUser < ActiveRecord::Base
  # Include default devise modules.
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable,
         :validatable, :confirmable
  DeviseJwtAuth.send_confirmation_email = true
  include DeviseJwtAuth::Concerns::User
  DeviseJwtAuth.send_confirmation_email = false
end
