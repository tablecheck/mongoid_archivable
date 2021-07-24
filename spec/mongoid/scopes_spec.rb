require 'spec_helper'

RSpec.describe 'Mongoid::Archivable scopes' do

  context 'when the document is archivable' do

    context 'when calling a class method' do

      let(:criteria) do
        Fish.fresh
      end

      it 'includes the archived_at criteria in the selector' do
        expect(criteria.selector).to eq({ 'fresh' => true })
      end
    end

    context 'when chaining a class method to unscoped' do

      let(:criteria) do
        Fish.unscoped.fresh
      end

      it 'does not include the archived_at in the selector' do
        expect(criteria.selector).to eq({ 'fresh' => true })
      end
    end

    context 'when chaining a class method to archived' do

      let(:criteria) do
        Fish.archived.fresh
      end

      it 'includes the archived_at $ne criteria in the selector' do
        expect(criteria.selector).to eq({
          'archived_at' => { '$ne' => nil }, 'fresh' => true
        })
      end
    end

    context 'when chaining a where to unscoped' do

      let(:criteria) do
        Fish.unscoped.where(fresh: true)
      end

      it 'includes no default scoping information in the selector' do
        expect(criteria.selector).to eq({ 'fresh' => true })
      end
    end
  end

  describe '.scoped' do

    it 'returns a scoped criteria' do
      expect(ArchivablePost.scoped.selector).to eq({})
    end
  end

  describe '.archived' do

    context 'when called on a root document' do

      let(:post) do
        ArchivablePost.create(title: 'testing')
      end

      before do
        post.archive
      end

      let(:archived) do
        ArchivablePost.archived
      end

      it 'returns the archived documents' do
        expect(archived).to eq([ post ])
      end
    end

    context 'when called on an embedded document' do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create
      end

      before do
        phone.archive
        person.reload
      end

      it 'returns the archived documents' do
        expect(person.archivable_phones.archived.to_a).to eq([ phone ])
      end

      it 'returns the correct count' do
        expect(person.archivable_phones.archived.count).to eq(1)
      end
    end
  end

  describe '.unscoped' do

    let(:unscoped) do
      ArchivablePost.unscoped
    end

    it 'returns an unscoped criteria' do
      expect(unscoped.selector).to eq({})
    end
  end
end
