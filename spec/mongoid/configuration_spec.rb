require "spec_helper"

module Mongoid
  module Archivable
    describe Configuration do
      describe '#archivable_field' do
        it 'initializes with default value set to :archived_at' do
          expect(Configuration.new.archivable_field).to eq(:archived_at)
        end

        it 'can be updated' do
          config = Configuration.new
          config.archivable_field = :myFieldName
          expect(config.archivable_field).to eq(:myFieldName)
        end
      end
    end
  end
end
