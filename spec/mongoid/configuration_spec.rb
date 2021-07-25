require 'spec_helper'

RSpec.describe Mongoid::Archivable::Configuration do
  context 'configuring the archived_field setting' do
    before do
      Mongoid::Archivable.configure do |c|
        c.archived_field = :my_field_name
      end
    end

    describe '.configure' do
      before do
        class ArchivableConfigured
          include Mongoid::Document
          include Mongoid::Archivable
        end
      end

      it 'allows custom setting of the archived_field' do
        archivable_configured = ArchivableConfigured.new
        expect(archivable_configured.attribute_names).to include('my_field_name')
      end

      after(:each) do
        Mongoid::Archivable.reset
      end
    end

    describe '.reset' do
      before do
        Mongoid::Archivable.reset

        # the configuration gets set at include time
        # so you need to reset before defining a new class
        class ArchivableConfiguredReset
          include Mongoid::Document
          include Mongoid::Archivable
        end
      end

      it 'restores the archived_field to the default setting' do
        archivable_configured = ArchivableConfiguredReset.new
        expect(archivable_configured.attribute_names).to include('archived_at')
      end
    end
  end

  describe '#archived_field' do
    it 'initializes with default value set to :archived_at' do
      expect(Mongoid::Archivable::Configuration.new.archived_field).to eq(:archived_at)
    end

    it 'can be updated' do
      config = Mongoid::Archivable::Configuration.new
      config.archived_field = :my_field_name
      expect(config.archived_field).to eq(:my_field_name)
    end
  end
end
