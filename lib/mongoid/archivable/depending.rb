# frozen_string_literal: true

module Mongoid
  module Association
    module Depending

      STRATEGIES = STRATEGIES.dup + %i[archive archive_without_callbacks]

      def apply_archive_dependencies!
        self.class._all_dependents.each do |association|
          dependent = association.try(:dependent)
          next unless dependent.in?(%i[archive archive_without_callbacks])
          send(:"_dependent_#{dependent}!", association)
        end
      end

      private

      def _dependent_archive!(association)
        return unless _association_archivable?(association)
        relation = send(association.name)
        return unless relation
        if relation.is_a?(Enumerable)
          relation.entries
          relation.each(&:archive)
        elsif relation.try(:archivable?)
          relation.archive
        end
      end

      def _dependent_archive_without_callbacks!(association)
        return unless _association_archivable?(association)
        relation = send(association.name)
        return unless relation
        relation.set(archive_at: Time.zone.now)
      end

      def _association_archivable?(association)
        relations[association.name].class_name.constantize.try(:archivable?)
      end
    end
  end
end
