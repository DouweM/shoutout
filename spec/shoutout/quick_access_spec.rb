require "spec_helper"

describe Shoutout::QuickAccess do

  let(:url) { "http://82.201.100.5:8000/radio538" }
  subject   { Shoutout::Stream.new(url) }

  describe "#audio_info" do

    let(:raw_audio_info) { "ice-samplerate=44100;ice-bitrate=128;ice-channels=2" }
    let(:audio_info) {
      {
        samplerate: 44100,
        bitrate:    128,
        channels:   2
      }
    }

    before(:each) do
      subject.stub(:headers).and_return(Shoutout::Headers.new("ice-audio-info" => raw_audio_info))
    end

    it "returns the parsed metadata" do
      subject.audio_info.should eq(audio_info)
    end
  end

  describe ".name" do

    it "creates a new instance" do
      Shoutout::Stream.should_receive(:new).with(url).and_return(double("stream").as_null_object)

      Shoutout::Stream.name(url)
    end

    it "calls #name on the opened connection" do
      Shoutout::Stream.any_instance.should_receive(:name)

      Shoutout::Stream.name(url)
    end
  end
end