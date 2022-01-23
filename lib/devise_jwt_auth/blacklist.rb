# frozen_string_literal: true

# don't serialize tokens
Devise::Models::Authenticatable::UNSAFE_ATTRIBUTES_FOR_SERIALIZATION << :tokens
