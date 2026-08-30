# typed: true
# frozen_string_literal: true

require "test_helper"

module RubyLsp
  module Rails
    module Support
      class SchemaTableLocationVisitorTest < ActiveSupport::TestCase
        # The cache is process wide, so don't leave entries behind for the other tests to pick up
        teardown do
          SchemaTableLocationVisitor.expire_cache
        end

        test "collects the location of tables defined with a string name" do
          source = <<~RUBY
            ActiveRecord::Schema[7.1].define(version: 1) do
              create_table "users", force: :cascade do |t|
                t.string "name"
              end

              create_table "posts", force: :cascade do |t|
                t.string "title"
              end
            end
          RUBY

          visitor = SchemaTableLocationVisitor.new
          Prism.parse(source).value.accept(visitor)

          posts_location = visitor.tables.fetch("posts")
          assert_equal(6, posts_location.start_line)
          assert_equal(8, posts_location.end_line)
        end

        test "collects the location of tables defined with a symbol name" do
          source = <<~RUBY
            ActiveRecord::Schema[7.1].define(version: 1) do
              create_table :users, force: :cascade do |t|
                t.string "name"
              end
            end
          RUBY

          visitor = SchemaTableLocationVisitor.new
          Prism.parse(source).value.accept(visitor)

          assert_equal(2, visitor.tables.fetch("users").start_line)
        end

        test ".find returns the location of the table's definition" do
          location = SchemaTableLocationVisitor.find(schema_source, "users") #: as !nil

          lines = location.slice.lines

          assert_equal("create_table \"users\", force: :cascade do |t|", lines.fetch(0).chomp)
          assert_equal("  end", lines.fetch(-1))
        end

        test ".find returns nil if the table is not found" do
          assert_nil(SchemaTableLocationVisitor.find(schema_source, "non_existing_table"))
        end

        test ".find does not parse the same source again while it is cached" do
          assert(SchemaTableLocationVisitor.find(schema_source, "users"))

          Prism.expects(:parse).never

          assert(SchemaTableLocationVisitor.find(schema_source, "users"))
        end

        test ".expire_cache makes the next lookup parse the source again" do
          assert(SchemaTableLocationVisitor.find(schema_source, "users"))

          SchemaTableLocationVisitor.expire_cache

          # Prepare the result before stubbing, otherwise this call is counted against the expectation
          empty_result = Prism.parse("")
          Prism.expects(:parse).once.returns(empty_result)

          assert_nil(SchemaTableLocationVisitor.find(schema_source, "users"))
        end

        private

        def schema_source
          @schema_source ||= File.read("#{dummy_root}/db/schema.rb")
        end
      end
    end
  end
end
