require "spec_helper"

describe Mongoid::Criteria::Scopable do

  context "when the document is archivable" do

    context "when calling a class method" do

      let(:criteria) do
        Fish.fresh
      end

      it "includes the archived_at criteria in the selector" do
        expect(criteria.selector).to eq({ "fresh" => true })
      end
    end

    context "when chaining a class method to unscoped" do

      let(:criteria) do
        Fish.unscoped.fresh
      end

      it "does not include the archived_at in the selector" do
        expect(criteria.selector).to eq({ "fresh" => true })
      end
    end

    context "when chaining a class method to archived" do

      let(:criteria) do
        Fish.archived.fresh
      end

      it "includes the archived_at $ne criteria in the selector" do
        expect(criteria.selector).to eq({
          "archived_at" => { "$ne" => nil }, "fresh" => true
        })
      end
    end

    context "when chaining a where to unscoped" do

      let(:criteria) do
        Fish.unscoped.where(fresh: true)
      end

      it "includes no default scoping information in the selector" do
        expect(criteria.selector).to eq({ "fresh" => true })
      end
    end
  end
end
