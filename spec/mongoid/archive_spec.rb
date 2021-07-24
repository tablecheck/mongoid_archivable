require 'spec_helper'

RSpec.describe 'Mongoid::Archivable#archive' do
  describe '#archive' do

    context 'when the document is a root' do

      let(:post) do
        ArchivablePost.create(title: 'testing')
      end

      before do
        post.archive
      end

      let(:raw) do
        ArchivablePost.collection.find(_id: post.id).first
      end

      it 'archives the document' do
        expect(raw['archived_at']).to be_within(1).of(Time.now)
      end

      it 'is still marked as persisted' do
        expect(post.persisted?).to eq(true)
      end

      it 'does not return the document in a find' do
        expect(ArchivablePost.find(post.id)).to eq post
      end

      it 'executes the before archive callbacks' do
        expect(post.before_archive_called).to be_truthy
      end

      it 'executes the after archive callbacks' do
        expect(post.after_archive_called).to be_truthy
      end
    end

    # context 'when the document is embedded' do
    #
    #   let(:person) do
    #     Person.create
    #   end
    #
    #   let(:phone) do
    #     person.archivable_phones.create(number: '911')
    #   end
    #
    #   before do
    #     phone.archive
    #   end
    #
    #   let(:raw) do
    #     Person.collection.find(_id: person.id).first
    #   end
    #
    #   it 'archives the document' do
    #     expect(raw['archivable_phones'].first['archived_at']).to be_within(1).of(Time.now)
    #   end
    #
    #   it 'does not return the document in a find' do
    #     expect {
    #       person.archivable_phones.find(phone.id)
    #     }.to raise_error(Mongoid::Errors::DocumentNotFound)
    #   end
    #
    #   it 'does not include the document in the relation' do
    #     expect(person.archivable_phones.scoped).to be_empty
    #   end
    #
    #   it 'executes the before archive callbacks' do
    #     expect(phone.before_archive_called).to be_truthy
    #   end
    #
    #   it 'executes the after archive callbacks' do
    #     expect(phone.after_archive_called).to be_truthy
    #   end
    # end

    context 'when the document has a dependent: :delete relation' do

      let(:post) do
        ArchivablePost.create(title: 'test')
      end

      let!(:author) do
        post.authors.create(name: 'poe')
      end

      before do
        post.archive
      end

      it 'cascades the dependent option' do
        expect(author.reload.archived_at).to be_a(Time)
      end
    end

    context 'when the document has a dependent: :restrict relation' do

      let(:post) do
        ArchivablePost.create(title: 'test')
      end

      let!(:title) do
        post.titles.create
      end

      before do
        begin
          post.archive
        rescue Mongoid::Errors::DeleteRestriction
        end
      end

      it 'does not archive the document' do
        expect(post).not_to be_archived
      end
    end
  end

  describe '#archive_without_callbacks' do

    context 'when the document is a root' do

      let(:post) do
        ArchivablePost.create(title: 'testing')
      end

      before do
        post.archive_without_callbacks
      end

      let(:raw) do
        ArchivablePost.collection.find(_id: post.id).first
      end

      it 'archives the document' do
        expect(raw['archived_at']).to be_within(1).of(Time.now)
      end

      it 'does not return the document in a find' do
        expect { ArchivablePost.unarchived.find(post.id) }.to raise_error(Mongoid::Errors::DocumentNotFound)
        expect { ArchivablePost.find(post.id) }.to_not raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    # context 'when the document is embedded' do
    #
    #   let(:person) do
    #     Person.create
    #   end
    #
    #   let(:phone) do
    #     person.archivable_phones.create(number: '911')
    #   end
    #
    #   before do
    #     phone.delete
    #   end
    #
    #   let(:raw) do
    #     Person.collection.find(_id: person.id).first
    #   end
    #
    #   it 'archives the document' do
    #     expect(raw['archivable_phones'].first['archived_at']).to be_within(1).of(Time.now)
    #   end
    #
    #   it 'does not return the document in a find' do
    #     expect {
    #       person.archivable_phones.find(phone.id)
    #     }.to raise_error(Mongoid::Errors::DocumentNotFound)
    #   end
    #
    #   it 'does not include the document in the relation' do
    #     expect(person.archivable_phones.scoped).to be_empty
    #   end
    # end

    context 'when the document has a dependent relation' do

      let(:post) do
        ArchivablePost.create(title: 'test')
      end

      let!(:author) do
        post.authors.create(name: 'poe')
      end

      before do
        post.delete
      end

      it 'does not cascade the dependent option' do
        expect {
          author.reload
        }.to_not raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context 'when the document has a dependent: :restrict relation' do

      let(:post) do
        ArchivablePost.create(title: 'test')
      end

      let!(:title) do
        post.titles.create
      end

      before do
        begin
          post.delete
        rescue Mongoid::Errors::DeleteRestriction
        end
      end

      it 'ignores restrict and archives the document' do
        expect(post).to be_archived
      end
    end
  end

  describe '#archived?' do

    context 'when the document is a root' do

      let(:post) do
        ArchivablePost.create(title: 'testing')
      end

      context 'when the document is archived' do

        before do
          post.archive
        end

        it 'returns true' do
          expect(post).to be_archived
        end

        it 'returns true for archived scope document' do
          expect(ArchivablePost.archived.last).to be_archived
        end
      end
    end

    context 'when the document is embedded' do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: '911')
      end

      context 'when the document is hard deleted' do

        before do
          phone.archive
        end

        it 'returns true' do
          expect(phone).to be_archived
        end
      end

      context 'when the document is archived' do

        before do
          phone.archive
        end

        it 'returns true' do
          expect(phone).to_not be_destroyed
          expect(phone).to be_archived
        end
      end

      context 'when the document has non-dependent relation' do
        let(:post) do
          ArchivablePost.create(title: 'test')
        end

        let!(:tag) do
          post.tags.create(text: 'tagie')
        end

        before do
          post.delete
        end

        it 'does not cascades the dependent option' do
          expect(tag.reload).to eq(tag)
        end
      end
    end
  end

  describe '#set' do

    let!(:post) do
      ArchivablePost.create
    end

    let(:time) do
      20.days.ago
    end

    let!(:set) do
      post.set(archived_at: time)
    end

    it 'persists the change' do
      expect(post.reload.archived_at).to be_within(1).of(time)
    end
  end
end
