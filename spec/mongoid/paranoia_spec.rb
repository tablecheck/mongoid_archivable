require "spec_helper"

describe Mongoid::Archivable do
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

  describe ".scoped" do

    it "returns a scoped criteria" do
      expect(ArchivablePost.scoped.selector).to eq({})
    end
  end

  describe ".archived" do

    context "when called on a root document" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      before do
        post.destroy
      end

      let(:archived) do
        ArchivablePost.archived
      end

      it "returns the archived documents" do
        expect(archived).to eq([ post ])
      end
    end

    context "when called on an embedded document" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create
      end

      before do
        phone.destroy
        person.reload
      end

      it "returns the archived documents" do
        expect(person.archivable_phones.archived.to_a).to eq([ phone ])
      end

      it "returns the correct count" do
        expect(person.archivable_phones.archived.count).to eq(1)
      end
    end
  end

  describe "#destroy!" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      before do
        puts 'yyy'
        post.destroy!
        puts 'zzz'
      end

      let(:raw) do
        ArchivablePost.collection.find(_id: post.id).first
      end

      it "hard deletes the document" do
        expect(raw).to be_nil
      end

      it "executes the before destroy callbacks" do
        expect(post.before_destroy_called).to be_truthy
      end

      it "executes the after destroy callbacks" do
        expect(post.after_destroy_called).to be_truthy
      end

      it "does not execute the before archive callbacks" do
        expect(post.before_archive_called).to be_falsey
      end

      it "does not execute the after archive callbacks" do
        expect(post.after_archive_called).to be_falsey
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: "911")
      end

      before do
        phone.destroy!
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "hard deletes the document" do
        expect(raw["archivable_phones"]).to be_empty
      end

      it "executes the before destroy callbacks" do
        expect(phone.before_destroy_called).to be_truthy
      end

      it "executes the after destroy callbacks" do
        expect(phone.after_destroy_called).to be_truthy
      end
    end

    context "when the document has a dependent relation" do

      let(:post) do
        ArchivablePost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.destroy!
      end

      it "cascades the dependent option" do
        expect {
          author.reload
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "#destroy" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      before do
        post.destroy
      end

      let(:raw) do
        ArchivablePost.collection.find(_id: post.id).first
      end

      it "archives the document" do
        expect(raw["archived_at"]).to be_within(1).of(Time.now)
      end

      it "is still marked as persisted" do
        expect(post.persisted?).to eq(true)
      end

      it "does not return the document in a find" do
        expect(ArchivablePost.find(post.id)).to eq post
      end

      it "executes the before destroy callbacks" do
        expect(post.before_destroy_called).to be_falsey
      end

      it "executes the after destroy callbacks" do
        expect(post.after_destroy_called).to be_falsey
      end

      it "does not execute the before archive callbacks" do
        expect(post.before_archive_called).to be_truthy
      end

      it "does not execute the after archive callbacks" do
        expect(post.after_archive_called).to be_truthy
      end
    end

    # context "when the document is embedded" do
    #
    #   let(:person) do
    #     Person.create
    #   end
    #
    #   let(:phone) do
    #     person.archivable_phones.create(number: "911")
    #   end
    #
    #   before do
    #     phone.destroy
    #   end
    #
    #   let(:raw) do
    #     Person.collection.find(_id: person.id).first
    #   end
    #
    #   it "archives the document" do
    #     expect(raw["archivable_phones"].first["archived_at"]).to be_within(1).of(Time.now)
    #   end
    #
    #   it "does not return the document in a find" do
    #     expect {
    #       person.archivable_phones.find(phone.id)
    #     }.to raise_error(Mongoid::Errors::DocumentNotFound)
    #   end
    #
    #   it "does not include the document in the relation" do
    #     expect(person.archivable_phones.scoped).to be_empty
    #   end
    #
    #   it "executes the before destroy callbacks" do
    #     expect(phone.before_destroy_called).to be_truthy
    #   end
    #
    #   it "executes the after destroy callbacks" do
    #     expect(phone.after_destroy_called).to be_truthy
    #   end
    # end

    context "when the document has a dependent: :delete relation" do

      let(:post) do
        ArchivablePost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.destroy
      end

      it "cascades the dependent option" do
        expect(author.reload.archived_at).to be_a(Time)
      end
    end

    context "when the document has a dependent: :restrict relation" do

      let(:post) do
        ArchivablePost.create(title: 'test')
      end

      let!(:title) do
        post.titles.create
      end

      before do
        begin
          post.destroy
        rescue Mongoid::Errors::DeleteRestriction
        end
      end

      it "does not destroy the document" do
        expect(post).not_to be_destroyed
      end
    end
  end

  describe "#destroyed?" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      context "when the document is hard deleted" do

        before do
          post.destroy!
        end

        it "returns true" do
          expect(post).to be_destroyed
        end
      end

      context "when the document is archived" do

        before do
          post.destroy
        end

        it "returns true" do
          expect(post).to be_destroyed
        end

        it "returns true for archived scope document" do
          expect(ArchivablePost.archived.last).to be_destroyed
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: "911")
      end

      context "when the document is hard deleted" do

        before do
          phone.destroy!
        end

        it "returns true" do
          expect(phone).to be_destroyed
        end
      end

      context "when the document is archived" do

        before do
          phone.archive
        end

        it "returns true" do
          expect(phone).to_not be_destroyed
          expect(phone).to be_archived
        end
      end
    end
  end

  describe "#archived?" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      context "when the document is hard deleted" do

        before do
          post.destroy!
        end

        it "returns true" do
          expect(post).to be_destroyed
          expect(post).to_not be_archived
        end
      end

      context "when the document is archived" do

        before do
          post.destroy
        end

        it "returns true" do
          expect(post).to be_archived
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: "911")
      end

      context "when the document is hard deleted" do

        before do
          phone.destroy!
        end

        it "returns true" do
          expect(phone).to be_destroyed
          expect(phone).to_not be_archived
        end
      end

      context "when the document is archived" do

        before do
          phone.destroy
        end

        it "returns true" do
          expect(phone).to be_archived
        end
      end

      context "when the document has non-dependent relation" do
        let(:post) do
          ArchivablePost.create(title: "test")
        end

        let!(:tag) do
          post.tags.create(text: "tagie")
        end

        before do
          post.delete
        end

        it "doesn't cascades the dependent option" do
          expect(tag.reload).to eq(tag)
        end

      end
    end
  end

  describe "#delete!" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      before do
        post.delete!
      end

      let(:raw) do
        ArchivablePost.collection.find(_id: post.id).first
      end

      it "hard deletes the document" do
        expect(raw).to be_nil
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: "911")
      end

      before do
        phone.delete!
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "hard deletes the document" do
        expect(raw["archivable_phones"]).to be_empty
      end
    end

    context "when the document has a dependent relation" do

      let(:post) do
        ArchivablePost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.delete!
      end

      it "does not cascade the dependent option" do
        expect {
          author.reload
        }.to_not raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end
  end

  describe "#delete" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      before do
        post.delete
      end

      let(:raw) do
        ArchivablePost.collection.find(_id: post.id).first
      end

      it "archives the document" do
        expect(raw["archived_at"]).to be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          ArchivablePost.find(post.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: "911")
      end

      before do
        phone.delete
      end

      let(:raw) do
        Person.collection.find(_id: person.id).first
      end

      it "archives the document" do
        expect(raw["archivable_phones"].first["archived_at"]).to be_within(1).of(Time.now)
      end

      it "does not return the document in a find" do
        expect {
          person.archivable_phones.find(phone.id)
        }.to raise_error(Mongoid::Errors::DocumentNotFound)
      end

      it "does not include the document in the relation" do
        expect(person.archivable_phones.scoped).to be_empty
      end
    end

    context "when the document has a dependent relation" do

      let(:post) do
        ArchivablePost.create(title: "test")
      end

      let!(:author) do
        post.authors.create(name: "poe")
      end

      before do
        post.delete
      end

      it "does not cascade the dependent option" do
        expect {
          author.reload
        }.to_not raise_error(Mongoid::Errors::DocumentNotFound)
      end
    end

    context "when the document has a dependent: :restrict relation" do

      let(:post) do
        ArchivablePost.create(title: "test")
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

      it "ignores restrict and destroys the document" do
        expect(post).to be_destroyed
      end
    end
  end

  describe "#remove" do

    let(:post) do
      ArchivablePost.new
    end

    let!(:time) do
      Time.now
    end

    before do
      post.remove
    end

    it "sets the archived flag" do
      expect(post).to be_destroyed
    end
  end

  describe "#restore" do

    context "when the document is a root" do

      let(:post) do
        ArchivablePost.create(title: "testing")
      end

      before do
        post.delete
        post.restore
      end

      it "removes the archived at time" do
        expect(post.archived_at).to be_nil
      end

      it "persists the change" do
        expect(post.reload.archived_at).to be_nil
      end

      it "marks document again as persisted" do
        expect(post.persisted?).to be_truthy
      end

      context "will run callback" do

        it "before restore" do
          expect(post.before_restore_called).to be_truthy
        end

        it "after restore" do
          expect(post.after_restore_called).to be_truthy
        end

        it "around restore" do
          expect(post.around_before_restore_called).to be_truthy
          expect(post.around_after_restore_called).to be_truthy
        end
      end
    end

    context "when the document is embedded" do

      let(:person) do
        Person.create
      end

      let(:phone) do
        person.archivable_phones.create(number: "911")
      end

      before do
        phone.delete
        phone.restore
      end

      it "removes the archived at time" do
        expect(phone.archived_at).to be_nil
      end

      it "persists the change" do
        expect(person.reload.archivable_phones.first.archived_at).to be_nil
      end
    end
  end

  describe "#restore_relations" do

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

    context "restores archivable associations" do
      before { prepare }

      it { expect { subject.restore_relations }.to change { ArchHasOne.count    }.by(1) }
      it { expect { subject.restore_relations }.to change { ArchHasMany.count   }.by(2) }
      it { expect { subject.restore_relations }.to change { ArchHabtm.count     }.by(3) }
      it { expect { subject.restore_relations }.to change { ArchBelongsTo.count }.by(1) }
    end

    context "does not affect embedded archivable documents" do
      before { prepare }

      it { expect{ subject.restore_relations}.to_not change{ subject.arch_embeds_one } }
      it { expect{ subject.restore_relations}.to_not change{ subject.arch_embeds_many.count } }
    end

    context "does not affect non-archivable documents" do
      before { prepare }

      it { expect{ subject.restore_relations}.to_not change{ NormHasOne.count    } }
      it { expect{ subject.restore_relations}.to_not change{ NormHasMany.count   } }
      it { expect{ subject.restore_relations}.to_not change{ NormHabtm.count     } }
      it { expect{ subject.restore_relations}.to_not change{ NormBelongsTo.count } }
      it { expect{ subject.restore_relations}.to_not change{ subject.norm_embeds_one } }
      it { expect{ subject.restore_relations}.to_not change{ subject.norm_embeds_many.count } }
    end

    context "recursion" do

      let!(:arch_habtm_norm_has_one)  { subject.arch_habtm.first.norm_has_one = NormHasOne.create  } # not restored
      let!(:arch_habtm_arch_has_one)  { subject.arch_habtm.first.arch_has_one = ArchHasOne.create  } # restored
      let!(:arch_habtm_norm_has_many) { 2.times.map { subject.arch_habtm.first.norm_has_many  = NormHasMany.create } } # not restored
      let!(:arch_habtm_arch_has_many) { 3.times.map { subject.arch_habtm.second.arch_has_many = ArchHasMany.create } } # restored

      # Untestable due to infinite recursion condition in #destroy
      # let!(:arch_habtm_norm_habtm)    { 3.times.map { subject.arch_habtm.second.norm_habtm.create } } # not restored
      # let!(:arch_habtm_recursive)     { 2.times.map { subject.arch_habtm.first.recursive.create }   } # restored

      before do
        subject.destroy
        subject.restore
      end

      it { expect { subject.restore_relations}.to change { ArchHasOne.count  }.by(2) }
      it { expect { subject.restore_relations}.to change { ArchHasMany.count }.by(3) }

      # Untestable due to infinite recursion condition in #destroy
      # it { expect{ ArchHabtm.unscoped.each(&:restore)}.to change { ArchHabtm.count }.by(5) }

      it { expect { subject.restore_relations }.to_not change { NormHasOne.count  } }
      it { expect { subject.restore_relations }.to_not change { NormHasMany.count } }
      it { expect { subject.restore_relations }.to_not change { NormHabtm.count   } }
    end
  end

  describe ".scoped" do

    let(:scoped) do
      ArchivablePost.scoped
    end

    it "returns a scoped criteria" do
      expect(scoped.selector).to eq({})
    end
  end

  describe "#set" do

    let!(:post) do
      ArchivablePost.create
    end

    let(:time) do
      20.days.ago
    end

    let!(:set) do
      post.set(:archived_at => time)
    end

    it "persists the change" do
      expect(post.reload.archived_at).to be_within(1).of(time)
    end
  end

  describe ".unscoped" do

    let(:unscoped) do
      ArchivablePost.unscoped
    end

    it "returns an unscoped criteria" do
      expect(unscoped.selector).to eq({})
    end
  end

  describe "#to_param" do

    let(:post) do
      ArchivablePost.new(title: "testing")
    end

    context "when the document is new" do

      it "still returns nil" do
        expect(post.to_param).to be_nil
      end
    end

    context "when the document is not archived" do

      before do
        post.save
      end

      it "returns the id as a string" do
        expect(post.to_param).to eq(post.id.to_s)
      end
    end

    context "when the document is archived" do

      before do
        post.save
        post.delete
      end

      it "returns the id as a string" do
        expect(post.to_param).to eq(post.id.to_s)
      end
    end
  end
end
