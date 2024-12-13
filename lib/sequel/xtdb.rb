# frozen_string_literal: true

require_relative "xtdb/version"
require "sequel"

module Sequel
  module XTDB
    class Error < StandardError; end
  end
end
