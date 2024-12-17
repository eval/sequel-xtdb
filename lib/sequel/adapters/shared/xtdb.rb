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
    end

    module DatasetMethods
    end
  end
end
