require 'spec_helper'

describe Redis::Types::Set do
  before :each do
    $redis.sadd "test", %w{foo bar}
    @s = Redis::Types::Set.new "test"
  end
  
  describe "#<<" do
    it "should add values" do
      @s.length.should == 2
      @s << "value"
      @s.length.should == 3
    end
  end

  describe "#save" do
    it "should persist the set to Redis" do
      @s << "value"
      @s.save
      s = Redis::Types::Set.new "test"
      s.current.should == Set.new(%w{foo bar value})
    end
  end

  describe "#destroy" do
    it "should remove the array from Redis" do
      @s.destroy
      @s.empty?.should be_true
      $redis.exists(@s.key).should be_false
    end
  end

  after :each do
    $redis.del "test"
  end
end
