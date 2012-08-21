require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Redis::Types::HashMap" do
  before :all do
    hash = Redis::Types::HashMap.new("test")
    hash[:foo] = "bar"
    hash.save
    @hash = Redis::Types::HashMap.new("test")
  end

  describe "#[]" do
    it "should return an existing string value" do
      @hash[:foo].should == "bar"
    end

    it "should allow indifferent access" do
      @hash["foo"].should == "bar"
    end
  end

  describe "#[]=" do
    it "should set the specified key to the specified value" do
      @hash[:yin] = "yang"
      @hash[:yin].should == "yang"
    end
  end

  after :all do
    @hash.destroy
  end
end
