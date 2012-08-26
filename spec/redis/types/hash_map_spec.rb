require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "Redis::Types::HashMap" do
  before :each do
    @hash = Redis::Types::HashMap.new("test")
    @hash[:foo] = "bar"
    @hash.save
  end

  describe "#new" do
    it "should create an empty hash by default" do
      Redis::Types::HashMap.new("foo").should be_empty
    end
    it "should generate a key if one is not provided" do
      Redis::Types::HashMap.new.key.should_not be_nil
    end
    it "should open an existing hash when provided a key" do
      hash = Redis::Types::HashMap.new("test")
      hash[:foo].should == "bar"
    end
    it "should allow the key to be provided in option hash" do
      hash = Redis::Types::HashMap.new(:key => :test)
      hash[:foo].should == "bar"
    end
    it "should merge values when data is provided in option hash" do
      hash = Redis::Types::HashMap.new("test", :data => {:yin => "yang"})
      hash[:foo].should == "bar"
      hash[:yin].should == "yang"
    end
  end

  describe "#[]" do
    it "should return an existing string value" do
      @hash[:foo].should == "bar"
    end

    it "should allow indifferent access" do
      @hash["foo"].should == "bar"
    end
  end

  describe "#[]=" do
    it "should set the specified key to the specified value" do
      @hash[:yin] = "yang"
      @hash[:yin].should == "yang"
    end
  end

  describe "#delete" do
    it "should remove the specified key from the hash" do
      @hash.delete(:foo)
      @hash.save
      Redis::Types::HashMap.new("test")[:foo].should be_nil
    end
  end

  describe "#each" do
    it "should iterate return an Enumerable" do
      @hash.each.should be_a(Enumerable)
    end

    it "should iterate through keys and values" do
      @hash.each do |key, value|
        key.to_s.should == "foo"
        value.should == "bar"
      end
    end
  end

  describe "#each_pair" do
    it "should iterate through keys and values" do
      @hash.each_pair do |key, value|
        key.to_s.should == "foo"
        value.should == "bar"
      end
    end
  end

  describe "#save" do
    it "should cause the hash to persist" do
      hash = Redis::Types::HashMap.new("foo", :data => {:key => "value"})
      $redis.hgetall("foo").should == {}
      hash.save
      $redis.hgetall("foo").should == {"key" => "value"}
    end
  end

  describe "#destroy" do
    it "should cause the hash to be deleted" do
      $redis.hgetall("test").should == {"foo" => "bar"}
      @hash.destroy
      $redis.hgetall("test").should == {}
    end
  end

  after :each do
    @hash.destroy
  end
end
