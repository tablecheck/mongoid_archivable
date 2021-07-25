require 'spec_helper'

RSpec.describe Mongoid::Archivable::Protected do

  let(:sport) do
    Sport.create
  end

  describe '#delete and #delete!' do

    context 'when the document is a root' do

      it 'prevents delete' do
        expect { sport.delete }.to raise_error(RuntimeError)
      end

      it 'allows delete!' do
        sport.delete!
        expect { sport.reload }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    # context 'when the document is embedded' do
    # end
  end

  describe '#destroy and #destroy!' do

    context 'when the document is a root' do

      it 'prevents destroy' do
        expect { sport.destroy }.to raise_error(RuntimeError)
      end

      it 'allows destroy!' do
        sport.destroy!
        expect { sport.reload }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    # context 'when the document is embedded' do
    # end
  end
end
