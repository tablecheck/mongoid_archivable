require 'mongoid/archivable/configuration'
require 'active_support'
require 'active_support/deprecation'

module Mongoid

  # Include this module to get archivable root level documents.
  # This will add a archived_at field to the +Document+, managed automatically.
  # Potentially incompatible with unique indices. (if collisions with archived items)
  #
  # @example Make a document archivable.
  #   class Person
  #     include Mongoid::Document
  #     include Mongoid::Archivable
  #   end
  module Archivable
    include Mongoid::Persistable::Deletable
    extend ActiveSupport::Concern

    class << self
      attr_accessor :configuration
    end

    def self.configuration
      @configuration ||= Configuration.new
    end

    def self.reset
      @configuration = Configuration.new
    end

    # Allow the archivable +Document+ to use an alternate field name for archived_at.
    #
    # @example
    #   Mongoid::Archivable.configure do |c|
    #     c.archivable_field = :myFieldName
    #   end
    def self.configure
      yield(configuration)
    end

    # class_methods do
    #   def archivable(options = {})
    #     Mongoid::Archivable::Installer.new(self, options).setup
    #   end
    # end

    included do
      class_attribute :archivable
      self.archivable = true

      field Archivable.configuration.archivable_field, as: :archived_at, type: Time

      scope :unarchived, -> { where(archived_at: nil) }
      scope :archived, -> { ne(archived_at: nil) }

      define_model_callbacks :archive
      define_model_callbacks :restore

      def archive(_options = {})
        run_callbacks(:archive) { archive_without_callbacks }
      end

      def archive_without_callbacks(_options = {})
        return false unless catch(:abort) { apply_archive_dependencies! }
        now = Time.now
        self.archived_at = now
        _archivable_update('$set' => { archivable_field => now })
        true
      end

      # Determines if this document is destroyed.
      #
      # @example Is the document destroyed?
      #   person.destroyed?
      #
      # @return [ true, false ] If the document is destroyed.
      #
      # @since 1.0.0
      def archived?
        !!archived_at
      end

      # Restores a previously archived document. Handles this by removing the
      # archived_at flag.
      #
      # @example Restore the document from archived state.
      #   document.restore
      #
      # For restoring associated documents use :recursive => true
      # @example Restore the associated documents from archived state.
      #   document.restore(:recursive => true)
      def restore(options = {})
        run_callbacks(:restore) { restore_without_callbacks(options) }
      end

      def restore_without_callbacks(options = {})
        _archivable_update('$unset' => { archivable_field => true })
        attributes.delete('archived_at') # todo: does this need database field name
        restore_relations if options[:recursive]
        true
      end

      def restore_relations
        self.relations.each_pair do |name, association|
          next unless association.dependent == :destroy
          relation = self.send(name)
          if relation.try(:archivable?)
            Array.wrap(relation).each do |doc|
              doc.restore(recursive: true)
            end
          end
        end
      end

      alias_method :delete!, :delete

      def delete
        Mongoid.logger.warn 'DEPRECATED: #delete called instead of #archive_without_callbacks'
        archive_without_callbacks
      end

      def destroy
        Mongoid.logger.warn 'DEPRECATED: #destroy called instead of #archive'
        archive
      end

      def destroy!
        run_callbacks(:destroy) { delete! }
      end

      private

      # Get the collection to be used for archivable operations.
      #
      # @example Get the archivable collection.
      #   document.archivable_collection
      #
      # @return [ Collection ] The root collection.
      def archivable_collection
        embedded? ? _root.collection : collection
      end

      # Get the field to be used for archivable operations.
      #
      # @example Get the archivable field.
      #   document.archivable_field
      #
      # @return [ String ] The archived at field.
      def archivable_field
        field = Archivable.configuration.archivable_field
        embedded? ? "#{atomic_position}.#{field}" : field
      end

      # @return [ Object ] Update result.
      #
      def _archivable_update(value)
        archivable_collection.find(atomic_selector).update_one(value)
      end

      def apply_archive_dependencies!
        self.class._all_dependents.each do |association|
          next unless association.try(:dependent) == :destroy
          _dependent_archive!(association)
        end
      end

      def _dependent_archive!(association)
        relation = send(association.name)
        if relation.try(:archivable?)
          if relation.is_a?(Enumerable)
            relation.entries
            relation.each(&:archive)
          else
            relation.archive
          end
        end
      end
    end
  end
end
