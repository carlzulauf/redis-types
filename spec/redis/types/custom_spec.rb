require 'spec_helper'

class Custom < Redis::Types::Hash
  strategy :merge
  namespace :test
  fixed_attrs :foo, :yin
end

describe "Redis::Types::Customizable" do
  before :each do
    @custom = Custom.new
    @custom.foo = "bar"
    @custom.yin = "yang"
    @custom.save
  end

  describe ".namespace" do
    it "should change the default for the custom class" do
      Custom.namespace.should == :test
    end

    it "should not change other classes that use the module" do
      Redis::Types::Hash.namespace.should be_nil
    end

    it "instances should use the specified namespace" do
      @custom.namespace.should == :test
    end
  end

  describe ".strategy" do
    it "should allow a strategy to be specify" do
      Custom.strategy.should == :merge
    end

    it "should use the specified strategy" do
      concurrent = Redis::Types::Hash.new(@custom.key, namespace: @custom.namespace)
      concurrent[:foo] = "bad"
      concurrent.save
      @custom.foo = "bag"
      @custom.save
      @custom.foo.should == "bad"
    end
  end

  after :each do
    @custom.destroy
  end
end
