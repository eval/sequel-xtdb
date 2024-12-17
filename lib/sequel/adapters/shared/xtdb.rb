module Sequel
  module XTDB
    module DatabaseMethods
      def database_type
        :xtdb
      end

      def primary_key(_table)
        # eg used for RETURNING on insert (prevents crash)
        :_id
      end

      # Get a dataset with `current`, `valid` and `system` set.
      #
      # For selects this creates the SETTING pre-amble, e.g. 'SETTING DEFAULT VALID_TIME ...':
      # ```
      # DB.as_of(current: 2.weeks.ago).select(Sequel.lit('current_timestamp')).single_value
      # ```
      #
      # A block can be provided as a convenience to stay in SQL-land (selects only):
      # ```
      # DB.as_of(current: 2.hours.ago) do
      #   DB["select current_timestamp"]
      # end.sql
      # =>
      # SETTING
      #  CURRENT_TIME TO TIMESTAMP '2024-12-17T12:59:48+01:00'
      # select current_timestamp
      # ```
      #
      # When doing inserts, the `_valid_from` will be added (if not provided):
      # ```
      # DB[:products].as_of(valid: 2.weeks.ago).insert(_id: 1, name: 'Spam')
      # ```
      def as_of(...)
        ds = @default_dataset.as_of(...)
        return ds unless block_given?

        yield.clone(append_sql: ds.select_setting_sql(""))
      end
    end

    module DatasetMethods
      Dataset.def_sql_method(self, :select,
        [["if opts[:values]",
          %w[values compounds order limit]],
          ["else",
            %w[setting select distinct columns from join where group having compounds order limit lock]]])

      def as_of(valid: nil, system: nil, current: nil)
        {valid: valid, system: system, current: current}.reject { |_k, v| v.nil? }.then do |opts|
          clone(opts)
        end
      end

      def server_version
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

      def select_setting_sql(sql)
        setting = opts.slice(:current, :valid, :system)
        return sql if setting.empty?

        cast_value = ->(v) do
          case v
          when DateTime, Time
            literal_append "TIMESTAMP ", v.iso8601
          when Date
            literal_append "DATE ", v.iso8601
          end
        end
        sql << "SETTING "
        sql << setting.map do |k, v|
          if k == :current
            literal_append "CURRENT_TIME TO TIMESTAMP ", v.iso8601
          else
            "DEFAULT #{k.upcase}_TIME AS OF #{cast_value[v]}"
          end
        end.join(", ")
        sql << " "
      end
    end
  end
end
