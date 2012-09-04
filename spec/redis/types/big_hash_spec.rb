require 'spec_helper'

describe "Redis::Types::BigHash" do
  before :each do
    @hash = Redis::Types::BigHash.new("test")
    @hash[:foo] = "bar"
  end
  describe "#[]" do
    it "should read existing values" do
      @hash[:foo].should == "bar"
    end
    it "should posess string/symbol indifferent access" do
      @hash["foo"].should == "bar"
    end
  end
  describe "#[]=" do
    it "should write values" do
      @hash[:yin] = "yang"
      @hash[:yin].should == "yang"
    end
  end
end
