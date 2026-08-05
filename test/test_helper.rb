# typed: true
# frozen_string_literal: true

# Configure Rails Environment
ENV["RAILS_ENV"] = "test"

require_relative "../test/dummy/config/environment"
ActiveRecord::Migrator.migrations_paths = [File.expand_path("../test/dummy/db/migrate", __dir__)]
ActiveRecord::Migrator.migrations_paths << File.expand_path("../db/migrate", __dir__)
require "rails/test_help"
require "mocha/minitest"
require "ruby_lsp/internal"
require "ruby_lsp/test_helper"
require "ruby_lsp/ruby_lsp_rails/addon"

module ActiveSupport
  class TestCase
    include RubyLsp::TestHelper

    def dummy_root
      File.expand_path("#{__dir__}/dummy")
    end

    # Waits until the Rails add-on finished booting the runner client and fails the test immediately if it fell back
    # to a NullClient, instead of hanging forever waiting for a real client that will never arrive
    def wait_for_rails_runner_client_boot
      addon = RubyLsp::Addon.addons.first #: as RubyLsp::Rails::Addon
      addon.join_boot_thread

      client = addon.rails_runner_client
      refute_instance_of(RubyLsp::Rails::NullClient, client, "Expected the Rails runner client to boot successfully")
    end
  end
end
