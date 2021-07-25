require 'spec_helper'

RSpec.describe 'Mongoid::Archivable#restore' do

  describe '#restore' do

    context 'when the document is a root' do

      let(:post) do
        ArchivablePost.create(title: 'testing')
      end

      before do
        post.archive
        post.restore
      end

      it 'removes the archived at time' do
        expect(post.archived_at).to be_nil
      end

      it 'persists the change' do
        expect(post.reload.archived_at).to be_nil
      end

      it 'marks document again as persisted' do
        expect(post.persisted?).to be_truthy
      end

      context 'will run callback' do

        it 'before restore' do
          expect(post.before_restore_called).to be_truthy
        end

        it 'after restore' do
          expect(post.after_restore_called).to be_truthy
        end

        it 'around restore' do
          expect(post.around_before_restore_called).to be_truthy
          expect(post.around_after_restore_called).to be_truthy
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

      before do
        phone.archive
        phone.restore
      end

      it 'removes the archived at time' do
        expect(phone.archived_at).to be_nil
      end

      it 'persists the change' do
        expect(person.reload.archivable_phones.first.archived_at).to be_nil
      end
    end
  end

  describe '#restore_relations' do

    subject { ArchBase.create }

    let!(:arch_has_one)     { subject.arch_has_one = ArchHasOne.create       }
    let!(:arch_has_many)    { 2.times.map { subject.arch_has_many.create }   }
    let!(:arch_habtm)       { 3.times.map { subject.arch_habtm.create }      }
    let!(:arch_belongs_to)  { subject.arch_belongs_to = ArchBelongsTo.create }
    let!(:arch_embeds_one)  { subject.arch_embeds_one = ArchEmbedsOne.new    }
    let!(:arch_embeds_many) { 2.times.map { subject.arch_embeds_many.build } }

    let!(:norm_has_one)     { subject.norm_has_one = NormHasOne.create       }
    let!(:norm_has_many)    { 2.times.map { subject.norm_has_many.create }   }
    let!(:norm_habtm)       { 3.times.map { subject.norm_habtm.create }      }
    let!(:norm_belongs_to)  { subject.norm_belongs_to = NormBelongsTo.create }
    let!(:norm_embeds_one)  { subject.norm_embeds_one = NormEmbedsOne.new    }
    let!(:norm_embeds_many) { 2.times.map { subject.norm_embeds_many.build } }

    let(:prepare) do
      subject.archive
      subject.restore
    end

    context 'restores archivable associations' do
      before { prepare }

      it do
        subject.restore_relations
      end

      it { expect { subject.restore_relations }.to change { ArchHasOne.unarchived.count    }.by(1) }
      it { expect { subject.restore_relations }.to change { ArchHasMany.unarchived.count   }.by(2) }
      it { expect { subject.restore_relations }.to change { ArchHabtm.unarchived.count     }.by(3) }
      it { expect { subject.restore_relations }.to change { ArchBelongsTo.unarchived.count }.by(1) }
    end

    context 'does not affect embedded archivable documents' do
      before { prepare }

      it { expect{ subject.restore_relations}.to_not change{ subject.arch_embeds_one } }
      it { expect{ subject.restore_relations}.to_not change{ subject.arch_embeds_many.unarchived.count } }
    end

    context 'does not affect non-archivable documents' do
      before { prepare }

      it { expect{ subject.restore_relations}.to_not change{ NormHasOne.count    } }
      it { expect{ subject.restore_relations}.to_not change{ NormHasMany.count   } }
      it { expect{ subject.restore_relations}.to_not change{ NormHabtm.count     } }
      it { expect{ subject.restore_relations}.to_not change{ NormBelongsTo.count } }
      it { expect{ subject.restore_relations}.to_not change{ subject.norm_embeds_one } }
      it { expect{ subject.restore_relations}.to_not change{ subject.norm_embeds_many.count } }
    end

    context 'recursion' do

      let!(:arch_habtm_norm_has_one)  { subject.arch_habtm.first.norm_has_one = NormHasOne.create  } # not restored
      let!(:arch_habtm_arch_has_one)  { subject.arch_habtm.first.arch_has_one = ArchHasOne.create  } # restored
      let!(:arch_habtm_norm_has_many) { 2.times.map { subject.arch_habtm.first.norm_has_many  = NormHasMany.create } } # not restored
      let!(:arch_habtm_arch_has_many) { 3.times.map { subject.arch_habtm.second.arch_has_many = ArchHasMany.create } } # restored

      # Untestable due to infinite recursion condition in #archive
      # let!(:arch_habtm_norm_habtm)    { 3.times.map { subject.arch_habtm.second.norm_habtm.create } } # not restored
      # let!(:arch_habtm_recursive)     { 2.times.map { subject.arch_habtm.first.recursive.create }   } # restored

      before do
        subject.archive
        subject.restore
      end

      it { expect { subject.restore_relations}.to change { ArchHasOne.unarchived.count  }.by(2) }
      it { expect { subject.restore_relations}.to change { ArchHasMany.unarchived.count }.by(3) }

      # Untestable due to infinite recursion condition in #archive
      # it { expect{ ArchHabtm.unscoped.each(&:restore)}.to change { ArchHabtm.unarchived.count }.by(5) }

      it { expect { subject.restore_relations }.to_not change { NormHasOne.count  } }
      it { expect { subject.restore_relations }.to_not change { NormHasMany.count } }
      it { expect { subject.restore_relations }.to_not change { NormHabtm.count   } }
    end
  end
end
