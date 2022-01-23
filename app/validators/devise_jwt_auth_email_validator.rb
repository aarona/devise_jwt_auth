# frozen_string_literal: true

# Email field validator.
class DeviseJwtAuthEmailValidator < ActiveModel::EachValidator
  EMAIL_REGEXP = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  class << self
    def validate?(email)
      email =~ EMAIL_REGEXP
    end
  end

  def validate_each(record, attribute, value)
    unless DeviseJwtAuthEmailValidator.validate?(value)
      # record.errors[attribute] << email_invalid_message
      record.errors.add(attribute, email_invalid_message)
    end
  end

  private

  def email_invalid_message
    # Try strictly set message:
    message = options[:message]

    if message.nil?
      # Try DeviseJwtAuth translations or fallback to ActiveModel translations
      message = I18n.t(:'errors.messages.not_email', default: :'errors.messages.invalid')
    end

    message
  end
end
