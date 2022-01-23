# frozen_string_literal: true

# ActiveSupport Concern for confirming users
module DeviseJwtAuth::Concerns::ConfirmableSupport
  extend ActiveSupport::Concern

  included do
    # Override standard devise `postpone_email_change?` method
    # for not to use `will_save_change_to_email?` & `email_changed?` methods.
    def postpone_email_change?
      postpone = self.class.reconfirmable &&
                 email_was != email &&
                 !@bypass_confirmation_postpone &&
                 email.present? &&
                 (!@skip_reconfirmation_in_callback || !email_was.nil?)
      @bypass_confirmation_postpone = false
      postpone
    end
  end
end
