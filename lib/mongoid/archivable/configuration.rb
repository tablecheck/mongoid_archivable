# frozen_string_literal: true

module Mongoid
  module Archivable
    class Configuration
      attr_accessor :archived_field,
                    :archived_scope,
                    :nonarchived_scope

      def initialize
        @archived_field = :archived_at
        @archived_scope = :archived
        @nonarchived_scope = :current
      end
    end
  end
end
