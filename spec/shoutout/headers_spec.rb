require "spec_helper"

describe Shoutout::Headers do

  let(:raw_headers) {
    "Content-Type: audio/mpeg\n" <<
      "icy-br:128\n" <<
      "ice-audio-info: ice-samplerate=44100;ice-bitrate=128;ice-channels=2\n" <<
      "icy-br:128\n" <<
      "icy-description:ARE YOU IN\n" <<
      "icy-genre:Various\n" <<
      "icy-name:RADIO538\n" <<
      "icy-pub:1\n" <<
      "icy-url:http://www.radio538.nl\n" <<
      "Server: Icecast 2.3.2-kh31\n" <<
      "icy-metaint:16000"
  }

  let(:headers) {
    {
      "Content-Type"    => "audio/mpeg",
      "icy-br"          => "128",
      "ice-audio-info"  => "ice-samplerate=44100;ice-bitrate=128;ice-channels=2",
      "icy-description" => "ARE YOU IN",
      "icy-genre"       => "Various",
      "icy-name"        => "RADIO538",
      "icy-pub"         => "1",
      "icy-url"         => "http://www.radio538.nl",
      "Server"          => "Icecast 2.3.2-kh31",
      "icy-metaint"     => "16000"
    }
  }

  subject { described_class.new(headers) }

  describe ".parse" do

    it "parses the headers" do
      described_class.should_receive(:new).with(headers)

      described_class.parse(raw_headers)
    end
  end

  describe "#initialize" do

    context "when provided a Hash" do

      it "updates self with the Hash" do
        described_class.any_instance.should_receive(:update).with(headers)

        described_class.new(headers)
      end
    end
  end

  describe "#[]" do

    context "when provided a Symbol" do

      context "when the header's key was originally camel cased" do

        it "returns the header's value" do
          subject[:content_type].should eq(headers["Content-Type"])
        end
      end

      context "when the header's key was originally lowercase" do

        it "returns the header's value" do
          subject[:Icy_Br].should eq(headers["icy-br"])
        end
      end
    end

    context "when provided a String" do

      context "when the header's key was originally camel cased" do

        it "returns the header's value" do
          subject["content-type"].should eq(headers["Content-Type"])
        end
      end

      context "when the header's key was originally lowercase" do

        it "returns the header's value" do
          subject["Icy-Br"].should eq(headers["icy-br"])
        end
      end
    end
  end

  describe "#[]=" do

    let(:content_type) { "text/plain" }

    context "when provided a Symbol key" do

      it "is saved on the hash" do
        subject[:content_type] = content_type

        subject.should have_key(:content_type)
      end

      it "can be read out again" do
        subject[:content_type] = content_type

        subject[:content_type].should eq(content_type)
        subject["content-type"].should eq(content_type)
        subject["Content-Type"].should eq(content_type)
      end
    end

    context "when provided a String key" do

      it "is saved on the hash" do
        subject["content-type"] = content_type

        subject.should have_key("content-type")
      end

      it "can be read out again" do
        subject["content-type"] = content_type

        subject[:content_type].should eq(content_type)
        subject["content-type"].should eq(content_type)
        subject["Content-Type"].should eq(content_type)
      end
    end
  end
end