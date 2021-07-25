# frozen_string_literal: true

module Mongoid
  module Archivable
    module Protected
      extend ActiveSupport::Concern

      included do
        include Mongoid::Persistable::Deletable

        alias :delete! :delete

        def delete
          raise '#delete not permitted. Use #archive_without_callbacks or #delete! instead.'
        end
        alias :remove :delete

        def destroy
          raise '#destroy not permitted. Use #archive or #destroy! instead.'
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
