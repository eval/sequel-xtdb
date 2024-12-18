require "sequel/adapters/utils/unmodified_identifiers"

module Sequel
  module XTDB
    Sequel::Database.set_shared_adapter_scheme :xtdb, self

    def self.mock_adapter_setup(db)
      db.instance_exec do
        @server_version = 0

        # def schema_parse_table(*)
        #  []
        # end
        # singleton_class.send(:private, :schema_parse_table)
        # adapter_initialize
        # extend(MockAdapterDatabaseMethods)
      end
    end

    module DatabaseMethods
      include UnmodifiedIdentifiers::DatabaseMethods # ensure lowercase identifiers

      def database_type
        :xtdb
      end

      def primary_key(_table)
        # eg used for RETURNING on insert (prevents crash)
        :_id
      end

      # Get a dataset with `current`, `valid` and `system` set.
      def as_of(...)
        @default_dataset.as_of(...)
      end
    end

    module DatasetMethods
      include UnmodifiedIdentifiers::DatasetMethods # ensure lowercase identifiers

      Dataset.def_sql_method(self, :select,
        [["if opts[:values]",
          %w[values compounds order limit]],
          ["else",
            %w[select distinct columns from join where group having compounds order limit lock]]])

      def as_of(valid: nil, system: nil, current: nil)
        {valid: valid, system: system, current: current}.reject { |_k, v| v.nil? }.then do |opts|
          clone(opts)
        end
      end

      def server_version
        # TODO 2_000_000 from xt.version() output
        # requires all def_sql_methods
        0
      end

      def insert_values_sql(sql)
        if (from_ix = opts[:columns].index(:_valid_from))
          opts[:values][from_ix] = Sequel.lit("TIMESTAMP ?", opts[:values][from_ix])
        end

        if (to_ix = opts[:columns].index(:_valid_to))
          opts[:values][to_ix] = Sequel.lit("TIMESTAMP ?", opts[:values][to_ix])
        end

        super
      end

      def insert_columns_sql(sql)
        if opts[:valid] && !opts[:columns].index(:_valid_from)
          opts[:columns] << :_valid_from
          opts[:values] << opts[:valid]
        end
        super
      end

      def select_sql
        sql = super

        if (setting = select_setting_sql)
          if sql.frozen?
            setting += sql
            setting.freeze
          elsif @opts[:append_sql] || @opts[:placeholder_literalizer]
            setting << sql
          else
            setting + sql
          end
        else
          sql
        end
      end

      def select_setting_sql
        setting = opts.slice(:current, :valid, :system)
        return if setting.empty?

        cast_value = ->(v) do
          type = case v
          when DateTime, Time then "TIMESTAMP"
          when Date then "DATE"
          end
          literal_append "#{type} ", v.iso8601
        end
        sql = "SETTING "
        sql.concat(setting.map do |k, v|
          if k == :current
            "CURRENT_TIME TO #{cast_value[v.to_time]}"
          else
            "DEFAULT #{k.upcase}_TIME AS OF #{cast_value[v]}"
          end
        end.join(", "))
        sql.concat " "
      end

      private

      def default_timestamp_format
        "'%Y-%m-%d %H:%M:%S'"
      end
    end
  end
end
