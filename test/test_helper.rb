# frozen_string_literal: true

require "bundler/setup"
require "active_record"
Bundler.require(:default)

require "minitest/autorun"
require "minitest/pride"
require "fakefs/safe"

require_relative "support/assertions"

ActiveRecord::Base.logger = ActiveSupport::Logger.new(ENV["VERBOSE"] ? $stdout : nil)
ActiveRecord::Migration.verbose = ENV["VERBOSE"]

# Migrations
ActiveRecord::Base.establish_connection adapter: "sqlite3", database: ":memory:"

ActiveRecord::Migration.create_table :addresses do |t|
  t.string :country_code
  t.string :administrative_area
  t.string :locality
  t.string :dependent_locality
  t.string :postal_code
  t.string :sorting_code
  t.string :address_line1
  t.string :address_line2
  t.string :organization
  t.string :given_name
  t.string :additional_name
  t.string :family_name
  t.string :locale
end

class Address < ActiveRecord::Base
  validates_address_format
end
