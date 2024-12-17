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

        Sequel.database_timezone = :utc
        Sequel.application_timezone = :local

        if (app_tz = @opts[:application_timezone])
          Sequel.extension(:named_timezones)
          Sequel.application_timezone = app_tz
        end

        super
      end

      def dataset_class_default
        Dataset
      end
    end

    class Dataset < Sequel::Postgres::Dataset
      include ::Sequel::XTDB::DatasetMethods

      private

      def default_timestamp_format
        "'%Y-%m-%d %H:%M:%S'"
      end
    end
  end
end
