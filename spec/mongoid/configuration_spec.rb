require 'spec_helper'

RSpec.describe Mongoid::Archivable::Configuration do
  context 'configuring the archivable_field setting' do
    before do
      Mongoid::Archivable.configure do |c|
        c.archivable_field = :myFieldName
      end
    end

    describe '.configure' do
      before do
        class ArchivableConfigured
          include Mongoid::Document
          include Mongoid::Archivable
        end
      end

      it 'allows custom setting of the archivable_field' do
        archivable_configured = ArchivableConfigured.new
        expect(archivable_configured.attribute_names).to include('myFieldName')
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

      it 'restores the archivable_field to the default setting' do
        archivable_configured = ArchivableConfiguredReset.new
        expect(archivable_configured.attribute_names).to include('archived_at')
      end
    end
  end

  describe '#archivable_field' do
    it 'initializes with default value set to :archived_at' do
      expect(Mongoid::Archivable::Configuration.new.archivable_field).to eq(:archived_at)
    end

    it 'can be updated' do
      config = Mongoid::Archivable::Configuration.new
      config.archivable_field = :myFieldName
      expect(config.archivable_field).to eq(:myFieldName)
    end
  end
end
