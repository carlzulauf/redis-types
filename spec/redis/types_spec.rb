require 'spec_helper'

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
      $redis.hmset :small_hash, *[:foo, "bar", :yin, "yang"]
      $redis.set :string, "a typical string"
      $redis.lpush :array, "foo"

      begin # loop ensures big hash is big enough
        $redis.hmset :big_hash, *(0..1_000).map {|i| ["key#{i}", "value#{i}"] }
      end while $redis.object(:encoding, :big_hash) == "zipmap"
      
      begin # loop ensures list is big enough
        $redis.rpush :list, (0..1_000).map{|i| "value#{i}" }
      end while $redis.object(:encoding, :list) == "ziplist"
    end

    it "should load a Hash for small Redis hashes" do
      Redis::Types.load(:small_hash).should be_a(Redis::Types::Hash)
    end

    it "should load a BigHash for big Redis hashes" do
      Redis::Types.load(:big_hash).should be_a(Redis::Types::BigHash)
    end

    it "should load a Hash when explicitly told to" do
      Redis::Types.load(:big_hash, :type => :hash_map).should be_a(Redis::Types::Hash)
    end

    it "should load a String for Redis strings" do
      Redis::Types.load(:string).should be_a(String)
    end

    it "should load an Array for Redis lists" do
      Redis::Types.load(:array).should be_a(Redis::Types::Array)
    end

    it "should loa a List for big Redis lists" do
      Redis::Types.load(:list).should be_a(Redis::Types::List)
    end

    after :all do
      $redis.del :small_hash, :big_hash, :string, :array, :list
    end
  end
end
