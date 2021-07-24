# frozen_string_literal: true

module Mongoid
  module Archivable
    class Configuration
      attr_accessor :archivable_field

      def initialize
        @archivable_field = :archived_at
      end
    end
  end
end
