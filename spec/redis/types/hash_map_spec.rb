require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Redis::Types::HashMap" do
  before :each do
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

  describe "#delete" do
    it "should remove the specified key from the hash" do
      @hash.delete(:foo)
      @hash.save
      Redis::Types::HashMap.new("test")[:foo].should be_nil
    end
  end

  describe "#each" do
    it "should iterate return an Enumerator" do
      @hash.each.should be_a(Enumerator)
    end

    it "should iterate through keys and values" do
      @hash.each do |key, value|
        key.to_s.should == "foo"
        value.should == "bar"
      end
    end
  end

  after :each do
    @hash.destroy
  end
end
