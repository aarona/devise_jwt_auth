# frozen_string_literal: true

# don't serialize tokens
Devise::Models::Authenticatable::BLACKLIST_FOR_SERIALIZATION << :tokens
