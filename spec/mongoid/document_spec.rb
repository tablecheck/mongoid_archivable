require "spec_helper"

describe Mongoid::Document do

  describe ".archivable?" do

    context "when Mongoid::Archivable is included" do
      subject { ArchivablePost }
      it "returns true" do
        expect(subject.archivable?).to eq true
      end
    end

    context "when Mongoid::Archivable not included" do
      subject { Author }
      it "returns true" do
        expect(subject.respond_to?(:archivable?)).to eq false
      end
    end
  end
end
