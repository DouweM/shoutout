require "spec_helper"

describe Shoutout::Stream do
  let(:url)           { "http://82.201.100.5:8000/radio538" }
  let(:uri)           { URI.parse(url) }
  subject!            { described_class.new(url) }
  let(:response_data) { File.read(File.expand_path("../../fixtures/ok_response", __FILE__)) }
  let(:socket)        { FakeTCPSocket.new(response_data) }

  before(:each) do
    TCPSocket.stub(:new).with(uri.host, uri.port).and_return(socket)

    described_class.stub(:new).with(url).and_return(subject)
  end

  after(:each) do
    subject.disconnect
  end

  describe ".open" do

    let(:block) { lambda { |_| } }

    it "creates a new instance" do
      described_class.should_receive(:new).with(url)

      described_class.open(url, &block)
    end

    it "opens a connection" do
      subject.should_receive(:connect)

      described_class.open(url, &block)
    end

    it "calls the block" do
      expect { |block|
        described_class.open(url, &block)
      }.to yield_with_args(subject)
    end

    it "closes the connection" do
      subject.should_receive(:disconnect).twice.and_call_original

      described_class.open(url, &block)
    end
  end

  describe ".metadata" do

    it "creates a new instance" do
      described_class.should_receive(:new).with(url)

      described_class.metadata(url)
    end

    it "calls #metadata on the opened connection" do
      subject.should_receive(:metadata)

      described_class.metadata(url)
    end
  end

  describe "#connect" do

    context "when already connected" do

      before(:each) do
        subject.connect
      end

      it "returns false" do
        subject.connect.should be_false
      end
    end

    context "when not connected" do

      it "connects" do
        subject.connect 

        subject.should be_connected
      end

      it "opens a socket" do
        TCPSocket.should_receive(:new).with(uri.host, uri.port)

        subject.connect
      end

      it "writes the HTTP request to the socket" do
        socket.should_receive(:puts).once.ordered.with("GET #{uri.path} HTTP/1.0")
        socket.should_receive(:puts).once.ordered.with("Icy-MetaData: 1")
        socket.should_receive(:puts).once.ordered.with(no_args)

        subject.connect
      end

      it "reads the headers" do
        subject.connect

        subject.metadata_interval.should eq(10)
      end

      context "when the response indicates a redirect" do

        let(:redirect_response_data)  { File.read(File.expand_path("../../fixtures/redirect_response", __FILE__)) }
        let(:redirect_socket)         { FakeTCPSocket.new(redirect_response_data) }

        before(:each) do
          TCPSocket.stub(:new).with(uri.host, uri.port).and_return(redirect_socket)
          TCPSocket.stub(:new).with("82.201.100.7", 8000).and_return(socket)
        end

        it "closes the connection" do
          subject.should_receive(:disconnect).twice.and_call_original

          subject.connect
        end

        it "updates the url" do
          subject.connect

          subject.url.should eq("http://82.201.100.7:8000/radio538")
        end

        it "opens a second connection" do
          subject.should_receive(:connect).twice.and_call_original

          subject.connect
        end

        it "returns true" do
          subject.connect.should be_true
        end
      end

      context "when the response indicates an error" do

        let(:response_data) { File.read(File.expand_path("../../fixtures/error_response", __FILE__)) }

        it "closes the connection" do
          subject.should_receive(:disconnect).twice.and_call_original

          subject.connect
        end

        it "returns false" do
          subject.connect.should be_false
        end
      end

      context "when the response indicates success" do

        context "when the response is unsupported" do

          let(:response_data) { File.read(File.expand_path("../../fixtures/unsupported_response", __FILE__)) }

          it "closes the connection" do
            subject.should_receive(:disconnect).twice.and_call_original

            subject.connect
          end

          it "returns false" do
            subject.connect.should be_false
          end
        end

        context "when the response is supported" do

          it "starts reading metadata in a thread" do
            Thread.should_receive(:new)

            subject.connect
          end

          it "returns true" do
            subject.connect.should be_true
          end
        end
      end
    end
  end

  describe "#disconnect" do

    context "when connected" do

      before(:each) do
        subject.connect
      end

      it "disconnects" do
        subject.disconnect 
        
        subject.should_not be_connected
      end

      it "closes the socket" do
        socket.should_receive(:close)

        subject.disconnect
      end

      it "returns true" do
        subject.disconnect.should be_true
      end
    end

    context "when not connected" do

      it "returns false" do
        subject.disconnect.should be_false
      end
    end
  end

  describe "#listen" do

    context "when connected" do

      before(:each) do
        subject.connect
      end

      after(:each) do
        subject.disconnect
      end

      it "joins the metadata reading thread" do
        Thread.any_instance.should_receive(:join)

        subject.listen
      end
    end
  end

  describe "#metadata" do

    context "when connected" do

      before(:each) do
        subject.connect
      end

      it "returns the metadata" do
        subject.metadata.now_playing.should eq("AVICII - WAKE ME UP")
      end
    end

    context "when not connected" do

      it "opens a connection" do
        subject.should_receive(:connect).and_call_original

        subject.metadata
      end

      it "closes the connection" do
        subject.should_receive(:disconnect).at_least(2).times.and_call_original

        subject.metadata
      end

      it "returns the metadata" do
        subject.metadata.now_playing.should eq("AVICII - WAKE ME UP")
      end
    end
  end

  describe "#metadata_change" do

    it "sets a block that is called when the metadata changes" do
      metadatas = []

      subject.metadata_change do |metadata|
        metadatas << metadata
      end

      subject.connect
      subject.listen

      metadatas[0].now_playing.should eq("ARMIN VAN BUUREN - THIS IS WHAT IT FEELS LIKE")
      metadatas[1].now_playing.should eq("AVICII - WAKE ME UP")
    end
  end
end