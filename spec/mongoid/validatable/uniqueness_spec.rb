require 'spec_helper'

RSpec.describe 'Mongoid::Archivable uniqueness validator' do

  describe '#valid?' do

    context 'when the document is a root document' do

      context 'when the document is archivable' do
        before do
          ArchivablePost.validates(:title, uniqueness: { conditions: -> { ArchivablePost.where(archived_at: nil) } })
        end

        after do
          ArchivablePost.reset_callbacks(:validate)
        end

        let!(:post) do
          ArchivablePost.create(title: 'testing')
        end

        context 'when the field is unique' do

          let(:new_post) do
            ArchivablePost.new(title: 'test')
          end

          it 'returns true' do
            expect(new_post).to be_valid
          end
        end

        context 'when the field is unique for non archived docs' do

          before do
            post.delete
          end

          let(:new_post) do
            ArchivablePost.new(title: 'testing')
          end

          it 'returns true' do
            expect(new_post).to be_valid
          end
        end

        context 'when the field is not unique for archived docs' do

          before do
            post = ArchivablePost.create(title: 'test')
            post.archive
          end

          let(:new_post) do
            ArchivablePost.new(title: 'test')
          end

          it 'returns true' do
            expect(new_post).to be_valid
          end
        end

        context 'when the field is not unique' do

          let(:new_post) do
            ArchivablePost.new(title: 'testing')
          end

          it 'returns false' do
            expect(new_post).not_to be_valid
          end
        end
      end
    end
  end
end
