# frozen_string_literal: true

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('config/environment', __dir__)
run Rails.application

# allow cross origin requests
require 'rack/cors'
use Rack::Cors do
  allow do
    origins '*'
    resource '*',
             headers: :any,
             expose: %w[access-token],
             methods: %i[get post options delete put]
  end
end
