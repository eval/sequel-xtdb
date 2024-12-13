require_relative "shared/xtdb"
require "sequel/adapters/postgres"

module Sequel
  module XTDB
    class Database < Sequel::Postgres::Database
      include ::Sequel::XTDB::DatabaseMethods

      set_adapter_scheme :xtdb

      private

      def adapter_initialize
        # XTDB can't handle this SET-command
        @opts[:force_standard_strings] = false
        super
      end

      def dataset_class_default
        Dataset
      end
    end

    class Dataset < Sequel::Postgres::Dataset
      include ::Sequel::XTDB::DatasetMethods
    end
  end
end
