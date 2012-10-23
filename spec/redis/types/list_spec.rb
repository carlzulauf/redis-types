require 'spec_helper'

describe Redis::Types::List do
  before :each do
    $redis.rpush "test", "foo"
    $redis.rpush "test", "bar"
    @a = Redis::Types::List.new "test"
  end
  
  describe "#<<" do
    it "should add values" do
      @a.length.should == 2
      @a << "value"
      @a.length.should == 3
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
