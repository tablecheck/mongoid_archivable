# frozen_string_literal: true

module Mongoid
  module Archivable
    module Protected
      extend ActiveSupport::Concern

      included do
        include Mongoid::Persistable::Deletable
        extend ActiveSupport::Concern

        alias :delete! :delete

        def delete
          Mongoid.logger.warn 'DEPRECATED: #delete called instead of #archive_without_callbacks'
          archive_without_callbacks
        end
        alias :remove :delete

        def destroy
          Mongoid.logger.warn 'DEPRECATED: #destroy called instead of #archive'
          archive
        end

        def destroy!(options = {})
          raise Errors::ReadonlyDocument.new(self.class) if readonly?
          self.flagged_for_destroy = true
          result = run_callbacks(:destroy) do
            if catch(:abort) { apply_destroy_dependencies! }
              delete!(options || {})
            else
              false
            end
          end
          self.flagged_for_destroy = false
          result
        end
      end
    end
  end
end
