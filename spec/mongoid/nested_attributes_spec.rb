require 'spec_helper'

RSpec.describe Mongoid::Attributes::Nested do
  describe '##{name}_attributes=' do
    context 'when the parent document is new' do
      context 'when the relation is an embeds many' do
        context 'when ids are passed' do

          let(:person) do
            Person.create
          end

          let(:address_one) do
            Address.new(street: 'Unter den Linden')
          end

          let(:address_two) do
            Address.new(street: 'Kurfeurstendamm')
          end

          let(:phone_one) do
            ArchivablePhone.new(number: '1')
          end

          let(:phone_two) do
            ArchivablePhone.new(number: '2')
          end

          before do
            person.addresses << [ address_one, address_two ]
          end

          # context 'when archive attributes are passed' do
          #   context 'when the ids match' do
          #     context 'when allow_archive is true' do
          #       context 'when the child is archivable' do
          #
          #         before(:all) do
          #           Person.send(:undef_method, :archivable_phones_attributes=)
          #           Person.accepts_nested_attributes_for :archivable_phones,
          #             allow_archive: true
          #         end
          #
          #         after(:all) do
          #           Person.send(:undef_method, :archivable_phones_attributes=)
          #           Person.accepts_nested_attributes_for :archivable_phones
          #         end
          #
          #         [ 1, '1', true, 'true' ].each do |truth|
          #
          #           context 'when passed a #{truth} with archive' do
          #             context 'when the parent is persisted' do
          #
          #               let!(:persisted) do
          #                 Person.create do |p|
          #                   p.archivable_phones << [ phone_one, phone_two ]
          #                 end
          #               end
          #
          #               context 'when setting, pulling, and pushing in one op' do
          #
          #                 before do
          #                   persisted.archivable_phones_attributes =
          #                     {
          #                     'bar' => { 'id' => phone_one.id, '_archive' => truth },
          #                     'foo' => { 'id' => phone_two.id, 'number' => '3' },
          #                     'baz' => { 'number' => '4' }
          #                   }
          #                 end
          #
          #                 it 'removes the first document from the relation' do
          #                   expect(persisted.archivable_phones.size).to eq(2)
          #                 end
          #
          #                 it 'does not delete the unmarked document' do
          #                   expect(persisted.archivable_phones.first.number).to eq('3')
          #                 end
          #
          #                 it 'adds the new document to the relation' do
          #                   expect(persisted.archivable_phones.last.number).to eq('4')
          #                 end
          #
          #                 it 'has the proper persisted count' do
          #                   expect(persisted.archivable_phones.count).to eq(1)
          #                 end
          #
          #                 it 'archives the removed document' do
          #                   expect(phone_one).to be_archiveed
          #                 end
          #
          #                 context 'when saving the parent' do
          #
          #                   before do
          #                     persisted.save
          #                   end
          #
          #                   it 'deletes the marked document from the relation' do
          #                     expect(persisted.reload.archivable_phones.count).to eq(2)
          #                   end
          #
          #                   it 'does not delete the unmarked document' do
          #                     expect(persisted.reload.archivable_phones.first.number).to eq('3')
          #                   end
          #
          #                   it 'persists the new document to the relation' do
          #                     expect(persisted.reload.archivable_phones.last.number).to eq('4')
          #                   end
          #                 end
          #               end
          #             end
          #           end
          #         end
          #       end
          #
          #       context 'when the child has defaults' do
          #
          #         before(:all) do
          #           Person.accepts_nested_attributes_for :appointments, allow_archive: true
          #         end
          #
          #         after(:all) do
          #           Person.send(:undef_method, :appointments_attributes=)
          #         end
          #         context 'when the parent is persisted' do
          #           context 'when the child returns false in a before callback' do
          #             context 'when the child is archivable' do
          #
          #               before(:all) do
          #                 Person.accepts_nested_attributes_for :archivable_phones, allow_archive: true
          #               end
          #
          #               after(:all) do
          #                 Person.send(:undef_method, :archivable_phones=)
          #                 Person.accepts_nested_attributes_for :archivable_phones
          #               end
          #
          #               let!(:persisted) do
          #                 Person.create(age: 42)
          #               end
          #
          #               let!(:phone) do
          #                 persisted.archivable_phones.create
          #               end
          #
          #               before do
          #                 persisted.archivable_phones_attributes =
          #                   { 'foo' => { 'id' => phone.id, 'number' => 42, '_archive' => true }}
          #               end
          #
          #               it 'does not archive the child' do
          #                 expect(persisted.reload.archivable_phones).not_to be_empty
          #               end
          #             end
          #           end
          #         end
          #       end
          #     end
          #   end
          # end
        end
      end
    end
  end
end
