require "spec_helper"

describe Shoutout::Util do

  describe ".camelize" do

    it "camelizes the passed string" do
      described_class.camelize("under_score").should eq("UnderScore")
    end
  end
end