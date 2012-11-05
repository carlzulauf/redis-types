require 'spec_helper'

describe Redis::Types::Array do
  before :each do
    $redis.lpush "test", "foo"
    $redis.lpush "test", "bar"
    @a = Redis::Types::Array.new "test"
  end
  
  describe "#<<" do
    it "should add values" do
      @a.length.should == 2
      @a << "value"
      @a.length.should == 3
    end
  end

  describe "#save" do
    it "should persist the array to Redis" do
      @a << "pop"
      @a.save
      a = Redis::Types::Array.new "test"
      a.pop.should == "pop"
    end
  end

  describe "#pop" do
    it "should unmarshal arbitrary objects" do
      @a << TestStruct.new("bar", "yang")
      @a.save
      a = Redis::Types::Array.new "test"
      v = a.pop
      v.foo.should == "bar"
      v.yin.should == "yang"
    end
  end

  describe "#destroy" do
    it "should remove the array from Redis" do
      @a.destroy
      @a.empty?.should be_true
      $redis.exists(@a.key).should be_false
    end
  end

  after :each do
    $redis.del "test"
  end
end
