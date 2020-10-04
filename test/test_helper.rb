# frozen_string_literal: true

require 'simplecov'
SimpleCov.formatter = SimpleCov::Formatter::HTMLFormatter
SimpleCov.start 'rails' do
  add_filter ['.bundle', 'test', 'config']
end

ENV['RAILS_ENV'] = 'test'
DEVISE_JWT_AUTH_ORM = (ENV['DEVISE_JWT_AUTH_ORM'] || :active_record).to_sym

puts "\n==> DeviseJwtAuth.orm = #{DEVISE_JWT_AUTH_ORM.inspect}"

require File.expand_path('dummy/config/environment', __dir__)
require 'active_support/testing/autorun'
require 'minitest/rails'
require 'mocha/minitest'
require 'database_cleaner'

FactoryBot.definition_file_paths = [File.expand_path('factories', __dir__)]
FactoryBot.find_definitions

Dir[File.join(__dir__, 'support/**', '*.rb')].sort.each { |file| require file }

# I hate the default reporter. Use ProgressReporter instead.
Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

class ActionDispatch::IntegrationTest
  def follow_all_redirects!
    follow_redirect! while response.status.to_s =~ /^3\d{2}/
  end
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods

  ActiveRecord::Migration.check_pending! if DEVISE_JWT_AUTH_ORM == :active_record

  strategies = { active_record: :transaction,
                 mongoid: :truncation }
  DatabaseCleaner.strategy = strategies[DEVISE_JWT_AUTH_ORM]
  setup { DatabaseCleaner.start }
  teardown { DatabaseCleaner.clean }

  def get_cookie_header(name, value)
    { 'HTTP_COOKIE' => "#{name}=#{value};" }
  end

  # Suppress OmniAuth logger output
  def silence_omniauth
    previous_logger = OmniAuth.config.logger
    OmniAuth.config.logger = Logger.new('/dev/null')
    yield
  ensure
    OmniAuth.config.logger = previous_logger
  end
end

class ActionController::TestCase
  include Devise::Test::ControllerHelpers

  setup do
    @routes = Dummy::Application.routes
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end
end

# TODO: remove it when support for Rails < 5 has been dropped
module Rails
  module Controller
    module Testing
      module Integration
        %w[get post patch put head delete get_via_redirect post_via_redirect].each do |method|
          define_method(method) do |path_or_action, **args|
            if Rails::VERSION::MAJOR >= 5
              super path_or_action, args
            else
              super path_or_action, args[:params], args[:headers]
            end
          end
        end
      end
    end
  end
end

module ActionController
  class TestCase
    include Rails::Controller::Testing::Integration
  end
end
