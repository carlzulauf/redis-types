require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Redis::Types" do
  it "should exist" do
    Redis.const_defined?(:Types).should be_true
  end
end
