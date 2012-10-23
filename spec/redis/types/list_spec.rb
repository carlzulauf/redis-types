require 'spec_helper'

describe Redis::Types::List do
  before :each do
    $redis.rpush "test", "foo"
    $redis.rpush "test", "bar"
    @a = Redis::Types::List.new "test"
    unless defined?(TestStruct)
      TestStruct = Struct.new(:foo, :yin)
    end
  end
  
  describe "#<<" do
    it "should add values" do
      @a.length.should == 2
      @a << "value"
      @a.length.should == 3
    end
    it "should allow chaining" do
      @a.length.should == 2
      @a << "value1" << "value2"
      @a.length.should == 4
    end
  end

  describe "#each" do
    it "should iterate through the values in order" do
      i = 0
      @a.each do |value|
        value.should == "foo" if i == 0
        value.should == "bar" if i == 1
        i += 1
      end
    end
    it "should yield unmarshalled arbitrary objects" do
      a = Redis::Types::List.new "each_marshal"
      a << TestStruct.new("bar", "yang")
      v = a.pop
      v.foo.should == "bar"
      v.yin.should == "yang"
    end
  end

  describe "#pop" do
    it "should remove and return the last element" do
      @a.pop.should == "bar"
      @a.length.should == 1
    end
    it "should unmarshall arbitrary objects" do
      @a << TestStruct.new("bar", "yang")
      v = @a.pop
      v.foo.should == "bar"
      v.yin.should == "yang"
    end
  end

  describe "#save" do
    it "should persist the array to Redis" do
      @a << "pop"
      @a.save
      a = Redis::Types::List.new "test"
      a.pop.should == "pop"
    end
  end

  after :each do
    $redis.del "test"
  end
end
