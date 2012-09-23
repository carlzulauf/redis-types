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

  after :each do
    $redis.del "test"
  end
end
