require "spec_helper"

describe Shoutout::Metadata do

  let(:raw_metadata) { "StreamTitle='ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE';StreamUrl='http://www.radio538.nl';" }

  let(:metadata) {
    {
      "StreamTitle" => "ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE",
      "StreamUrl"   => "http://www.radio538.nl"
    }
  }

  subject { described_class.new(metadata) }

  describe ".parse" do

    it "parses the metadata" do
      described_class.should_receive(:new).with(metadata)

      described_class.parse(raw_metadata)
    end
  end

  describe "#initialize" do

    context "when provided a Hash" do

      it "updates self with the Hash" do
        described_class.any_instance.should_receive(:update).with(metadata)

        described_class.new(metadata)
      end
    end
  end

  describe "#[]" do

    context "when provided a Symbol" do

      it "returns the metadata" do
        subject[:stream_title].should eq(metadata["StreamTitle"])
      end
    end

    context "when provided a String" do

      it "returns the header's value" do
        subject["StreamTitle"].should eq(metadata["StreamTitle"])
      end
    end
  end

  describe "#[]=" do

    let(:stream_title) { "AVICII - WAKE ME UP" }

    context "when provided a Symbol key" do

      it "is saved on the hash" do
        subject[:stream_title] = stream_title

        subject.should have_key(:stream_title)
      end

      it "can be read out again" do
        subject[:stream_title] = stream_title

        subject[:stream_title].should eq(stream_title)
        subject["StreamTitle"].should eq(stream_title)
      end
    end

    context "when provided a String key" do

      it "is saved on the hash" do
        subject["StreamTitle"] = stream_title

        subject.should have_key("StreamTitle")
      end

      it "can be read out again" do
        subject["StreamTitle"] = stream_title

        subject[:stream_title].should eq(stream_title)
        subject["StreamTitle"].should eq(stream_title)
      end
    end
  end
end