# frozen_string_literal: true

require 'active_support'
require 'mongoid/archivable/version'
require 'mongoid/archivable/configuration'
require 'mongoid/archivable/depending'
require 'mongoid/archivable/protected'

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
    extend ActiveSupport::Concern

    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def reset
        @configuration = Configuration.new
      end

      # Set an alternate field name for archived_at.
      #
      # @example
      #   Mongoid::Archivable.configure do |c|
      #     c.archived_field = :my_field_name
      #   end
      def configure
        yield(configuration)
      end
    end

    # class_methods do
    #   def archivable(options = {})
    #     Mongoid::Archivable::Installer.new(self, options).setup
    #   end
    # end

    included do
      class_attribute :archivable
      self.archivable = true

      config = Archivable.configuration

      field config.archived_field, as: :archived_at, type: Time

      scope config.nonarchived_scope, -> { where(archived_at: nil) }
      scope config.archived_scope, -> { ne(archived_at: nil) }

      define_model_callbacks :archive
      define_model_callbacks :restore

      def archive(options = {})
        return if archived?
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        run_callbacks(:archive) do
          if catch(:abort) { apply_archive_dependencies! }
            archive_without_callbacks(options || {})
          else
            false
          end
        end
      end

      def archive_without_callbacks(_options = {})
        return if archived?
        raise Errors::ReadonlyDocument.new(self.class) if readonly?
        now = Time.now
        self.archived_at = now
        _archivable_update('$set' => { archived_field => now })
        true
      end

      # Determines if this document is archived.
      #
      # @example Is the document destroyed?
      #   person.destroyed?
      #
      # @return [ true, false ] If the document is destroyed.
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
      #   document.restore(recursive: true)
      def restore(options = {})
        return unless archived?
        run_callbacks(:restore) { restore_without_callbacks(options) }
      end

      def restore_without_callbacks(options = {})
        return unless archived?
        _archivable_update('$unset' => { archived_field => true })
        attributes.delete('archived_at') # TODO: does this need database field name
        restore_relations if options[:recursive]
        true
      end

      def restore_relations
        relations.each_pair do |name, association|
          next unless association.dependent.in?(%i[archive archive_all])
          next unless _association_archivable?(association)
          relation = send(name)
          next unless relation
          Array.wrap(relation).each do |doc|
            doc.restore(recursive: true)
          end
        end
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
      #   document.archived_field
      #
      # @return [ String ] The archived at field.
      def archived_field
        field = Archivable.configuration.archived_field
        embedded? ? "#{atomic_position}.#{field}" : field
      end

      # @return [ Object ] Update result.
      #
      def _archivable_update(value)
        archivable_collection.find(atomic_selector).update_one(value)
      end
    end
  end
end
