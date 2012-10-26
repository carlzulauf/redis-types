require 'spec_helper'

describe "Redis::Types::ClientMethods" do
  describe "#new" do
    it "should allow a namespace to be specified" do
      t = Redis::Types::Hash.new(:namespace => "test")
      t.namespace.should == "test"
    end
    it "should allow a key to be specified" do
      t = Redis::Types::Hash.new("test")
      t.key.should == "test"
    end
    it "should allow a key and namespace to be specified" do
      t = Redis::Types::Hash.new(:key => "foo", :namespace => "test")
      t.key.should == "foo"
      t.namespace.should == "test"
    end
    it "should allow a redis client to be provided" do
      redis = Redis.new(:db => 5)
      t = Redis::Types::Hash.new(:redis => redis)
      t.redis.client.db.should == 5
    end
  end
end
