# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"
ENV["SHOPIFY_API_KEY"] ||= "test-api-key"
ENV["SHOPIFY_API_SECRET"] ||= "test-api-secret"
ENV["HOST"] ||= "https://app.test.example"
require_relative "../config/environment"
require "rails/test_help"

require "minitest/autorun"
require "webmock/minitest"
require "mocha/minitest"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)

    fixtures :all
  end
end
