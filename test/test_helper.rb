# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:default)

require "minitest/autorun"
require "minitest/pride"
require "fakefs/safe"

require_relative "support/assertions"
