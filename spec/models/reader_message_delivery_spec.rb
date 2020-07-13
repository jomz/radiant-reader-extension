require File.dirname(__FILE__) + '/../spec_helper'

describe ReaderMessageDelivery do
  before(:each) do
    @reader_message_delivery = ReaderMessageDelivery.new
  end

  it "should be valid" do
    @reader_message_delivery.should be_valid
  end
end
