require 'spec_helper'

describe "Redis::Types::BigHash" do

  before :each do
    @hash = Redis::Types::BigHash.new("test")
    @hash[:foo] = "bar"
  end

  describe "#save" do
    it "should return true for compatibility" do
      @hash.save.should be_true
    end
  end

  describe "#==" do
    it "should return true for hashes with the same key" do
      hash = Redis::Types::BigHash.new("test")
      (@hash == hash).should be_true
    end
    it "should return false for hashes with different keys" do
      hash = Redis::Types::BigHash.new("foo")
      (@hash == hash).should be_false
    end
  end

  describe "#<=>" do
    it "should return 0 when keys are the same" do
      hash = Redis::Types::BigHash.new("test")
      (@hash <=> hash).should == 0
    end
    it "should return a 1 when the right key comes before the left key alphabetically" do
      hash = Redis::Types::BigHash.new("a key")
      (@hash <=> hash).should == 1
    end
    it "should return a -1 when the right key comes after the left key alphabetically" do
      hash = Redis::Types::BigHash.new("z key")
      (@hash <=> hash).should == -1
    end
  end

  describe "#[]" do
    it "should read existing values" do
      @hash[:foo].should == "bar"
    end
    it "should possess string/symbol indifferent access" do
      @hash["foo"].should == "bar"
    end
  end

  describe "#[]=" do
    it "should write values" do
      @hash[:yin] = "yang"
      @hash[:yin].should == "yang"
    end
    it "should marshal objects" do
      class Foo; attr_accessor :test; end
      @hash[:key]   = Foo.new.tap{|foo| foo.test = "bar" }
      @hash[:int]   = 12_345
      @hash[:float] = 12.345
      @hash[:key].should      be_a(Foo)
      @hash[:key].test.should == "bar"
      @hash[:int].should      === 12_345
      @hash[:float].should    === 12.345
    end
  end

  describe "#each" do
    it "should iterate through a hash with one value" do
      @hash.each do |key,value|
        key.should == "foo"
        value.should == "bar"
      end
    end
    it "should iterate through a hash with multiple values" do
      @hash[:yin] = "yang"
      @hash.each do |key, value|
        %w{foo yin}.member?(key).should be_true
        value.should == "bar" if key == "foo"
        value.should == "yang" if key == "yin"
      end
    end
  end

  describe "#find" do
    it "should find existing keys" do
      @hash.find{|k,v| k == "foo" }.should == ["foo", "bar"]
    end
    it "should not find keys that haven't been added yet" do
      @hash.find{|k,v| k == "something" }.should be_nil
    end
  end

  after :each do
    @hash.destroy
  end
end
