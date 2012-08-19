require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Redis::Types" do
  it "should exist" do
    Redis.const_defined?(:Types).should be_true
  end

  it "should respond to .load, .open, and .find" do
    Redis::Types.respond_to?(:load).should be_true
    Redis::Types.respond_to?(:open).should be_true
    Redis::Types.respond_to?(:find).should be_true
  end

  it ".load, .open, and .find should all be the same method" do
    Redis::Types.method(:load).should == Redis::Types.method(:open)
    Redis::Types.method(:load).should == Redis::Types.method(:find)
  end

  describe ".load" do
    before :all do
      $redis.hmset  :small_hash, *[:foo, "bar", :yin, "yang"]
      $redis.hmset  :big_hash,   *(0..1_000).map {|i| ["key#{i}", "value#{i}"] }
      $redis.set    :string, "a typical string"
    end

    it "should load a HashMap for small Redis hashes" do
      Redis::Types.load(:small_hash).should be_a(Redis::Types::HashMap)
    end

    it "should load a BigHash for big Redis hashes" do
      Redis::Types.load(:big_hash).should be_a(Redis::Types::BigHash)
    end

    it "should load a HashMap when the large hash size is increased" do
      Redis::Types.load(:big_hash, :large_hash => 2_000).should be_a(Redis::Types::HashMap)
    end

    it "should load a String for Redis strings" do
      Redis::Types.load(:string).should be_a(String)
    end

    after :all do
      $redis.del :small_hash, :big_hash
    end
  end
end
