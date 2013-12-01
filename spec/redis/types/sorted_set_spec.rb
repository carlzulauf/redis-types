require 'spec_helper'

describe Redis::Types::SortedSet do
  before :each do
    $redis.zadd "test", [1, :foo, 2, :bar]
    @s = Redis::Types::SortedSet.new "test"
  end

  describe "#add" do
    it "should add values" do
      @s.length.should == 2
      @s.add "value", 3
      @s.length.should == 3
    end
  end

  describe "#destroy" do
    it "should remove the sorted set from Redis" do
      @s.destroy
      $redis.exists(@s.key).should be_false
    end
  end

  describe "#first" do
    it "should return just one element when called without params" do
      @s.first.should == "foo"
    end

    it "should return an array of specified length" do
      @s.first(2).should == %w{foo bar}
    end
  end

  describe "#delete" do
    it "should remove the specified element from the set" do
      @s.delete "bar"
      @s.first(2).should == %w{foo}
    end
  end

  after :each do
    $redis.del "test"
  end
end
