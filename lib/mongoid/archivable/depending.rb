# frozen_string_literal: true

module Mongoid
  module Association
    module Depending

      STRATEGIES = STRATEGIES.dup + %i[archive archive_all]

      def apply_archive_dependencies!
        self.class._all_dependents.each do |association|
          dependent = association.try(:dependent)
          next if !dependent || dependent.in?(%i[delete_all destroy])
          send(:"_dependent_#{dependent}!", association)
        end
      end

      private

      def _dependent_archive!(association)
        return unless _warn_association_archivable?(association)
        relation = send(association.name)
        return unless relation
        if relation.is_a?(Enumerable)
          relation.entries
          relation.each(&:archive)
        elsif relation.try(:archivable?)
          relation.archive
        end
      end

      def _dependent_archive_all!(association)
        return unless _warn_association_archivable?(association)
        relation = send(association.name)
        return unless relation
        relation.set(archive_at: Time.zone.now)

        # TODO: this code enables dependency recursion. Untested.
        # dependents = relation.respond_to?(:dependents) && relation.dependents
        # if dependents && dependents.reject {|dep| dep.try(:dependent).in?(%i[delete_all destroy]) }.blank?
        #   relation.set(archive_at: Time.zone.now)
        # else
        #   ::Array.wrap(send(association.name)).each { |rel| rel.archive }
        # end
      end

      def _warn_association_archivable?(association)
        result = _association_archivable?(association)
        Mongoid.logger.warn "Non-archivable association: #{association.name}" unless result
        result
      end

      def _association_archivable?(association)
        relations[association.name].class_name.constantize.try(:archivable?)
      end
    end
  end
end
