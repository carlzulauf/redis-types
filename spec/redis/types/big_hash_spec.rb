require 'spec_helper'

describe "Redis::Types::BigHash" do

  before :each do
    @hash = Redis::Types::BigHash.new("test")
    @hash[:foo] = "bar"
  end

  describe ".new" do
    it "should default to a non-null random key" do
      Redis::Types::BigHash.new.key.should_not be_nil
    end
    it "should allow a key to be specified" do
      h1 = Redis::Types::BigHash.new("foo")
      h2 = Redis::Types::BigHash.new(:key => "bar")
      h1.key.should == "foo"
      h2.key.should == "bar"
    end
    it "should allow data to be supplied" do
      hash = Redis::Types::BigHash.new :data => {:foo => "bar"}
      hash[:foo].should == "bar"
      hash.destroy
    end
    it "should allow a default value to be supplied" do
      hash = Redis::Types::BigHash.new :default => 17
      hash[:missing].should == 17
    end
    it "should allow a default proc to be supplied" do
      hash = Redis::Types::BigHash.new{ |hash, key| "#{key} bar"}
      hash[:foo].should == "foo bar"
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
    it "should return nil on missing keys" do
      @hash["blah"].should be_nil
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

  describe "#assoc" do
    it "should return requested key and its value in an array" do
      @hash.assoc(:foo).should == [:foo, "bar"]
    end
    it "should return nil on missing keys" do
      @hash.assoc(:blah).should be_nil
    end
  end

  describe "#clear" do
    it "should remove everything" do
      @hash[:yin] = "yang"
      @hash.clear
      @hash[:foo].should be_nil
      @hash[:yin].should be_nil
    end
  end

  describe "#default" do
    it "should return nil by default" do
      @hash.default.should be_nil
    end
  end

  describe "#default=" do
    it "should change what #default returns" do
      @hash.default = "foo"
      @hash.default.should == "foo"
    end
    it "should change what missing keys return" do
      @hash.default = "foo"
      @hash[:missing].should == "foo"
    end
  end

  describe "#default_proc=" do
    it "should change what #default_proc returns" do
      @hash.default_proc = Proc.new{|hash, key| key + 1 }
      @hash.default_proc.call({},1) == 2
    end
    it "should change what missing keys return" do
      @hash.default_proc = Proc.new{|hash, key| "#{key} bar" }
      @hash[:missing].should == "missing bar"
    end
  end

  describe "#delete" do
    it "should remove a single key" do
      @hash.delete(:foo)
      @hash[:foo].should be_nil
    end
    it "should leave other keys alone" do
      @hash[:yin] = "yang"
      @hash.delete(:foo)
      @hash[:yin].should == "yang"
    end
    it "should return the current value" do
      @hash.delete(:foo).should == "bar"
    end
  end

  describe "#delete_if" do
    it "should remove keys when the passed block returns true" do
      @hash[:yin] = "yang"
      @hash[:foo].should == "bar"
      @hash.delete_if{|key,value| key == "foo" }
      @hash[:foo].should be_nil
      @hash[:yin].should == "yang"
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
    it "should return the hash" do
      @hash.each{|k,v| nil }.should be_a(Redis::Types::BigHash)
    end
    it "should return an Enumerator when no block is given" do
      @hash.each.should be_a(Enumerable)
    end
  end

  describe "#each_key" do
    it "should iterate through all keys" do
      @hash[:yin] = "yang"
      @hash.each_key do |key|
        %w{foo yin}.member?(key).should be_true
      end
    end
  end

  describe "#each_value" do
    it "should iterate through all values" do
      @hash[:yin] = "yang"
      @hash.each_value do |value|
        %w{bar yang}.member?(value).should be_true
      end
    end
  end

  describe "#empty?" do
    it "should return false for a hash with values" do
      @hash.empty?.should be_false
    end
    it "should return true for an empty hash" do
      Redis::Types::BigHash.new("empty").empty?.should be_true
    end
  end

  describe "#eql?" do
    it "should return true for the same hash" do
      hash = Redis::Types::BigHash.new("test")
      @hash.eql?(hash).should be_true
    end
    it "should return false for different hash" do
      hash = Redis::Types::BigHash.new("other")
      @hash.eql?(hash).should be_false
    end
    it "should return true for any hash with the same contents" do
      @hash.eql?("foo" => "bar").should be_true
      @hash.eql?({:foo => "bar"}.with_indifferent_access).should be_true
    end
  end

  describe "#fetch" do
    it "should return an existing value" do
      @hash.fetch(:foo).should == "bar"
    end
    it "should return the default when the key doesn't exist" do
      @hash.fetch(:bad, "default").should == "default"
    end
    it "should return the result of a block when passed a block and key doesn't exist" do
      @hash.fetch(:bad){ "default" }.should == "default"
    end
    it "should raise a key error when key isn't present and no default given" do
      expect{ @hash.fetch(:bad) }.to raise_error(KeyError)
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

  describe "#flatten" do
    it "should return a flat array of keys and values" do
      @hash.flatten.should == ["foo", "bar"]
    end
  end

  describe "#has_key?" do
    it "should return true for an existing key" do
      @hash.has_key?(:foo).should be_true
    end
    it "should return false for a missing key" do
      @hash.has_key?(:bad).should be_false
    end
  end

  describe "#has_value?" do
    it "should return true for an existing value" do
      @hash.has_value?("bar").should be_true
    end
    it "should return false for a missing value" do
      @hash.has_value?("bad").should be_false
    end
  end

  describe "#hash" do
    it "should produce an identical hash to a Hash with the same contents" do
      @hash.hash.should == {"foo" => "bar"}.hash
    end
    it "should produce a different hash than a Hash with different contents" do
      @hash.hash.should_not == {"yin" => "yang"}.hash
    end
  end

  describe "#invert" do
    it "should reverse the order of keys and values" do
      @hash.invert.should == {"bar" => "foo"}
    end
  end

  describe "#key" do
    it "should return the redis key if no argument is supplied" do
      @hash.key.should == "test"
    end
    it "should return the value for a key when a key is supplied" do
      @hash.key(:foo).should == "bar"
    end
    it "should return nil for when a key is supplied and doesn't exist" do
      @hash.key(:bad).should be_nil
    end
    it "should raise an error when more than one argument is supplied" do
      expect{ @hash.key(:one,:two) }.to raise_error(ArgumentError)
    end
  end

  describe "#keys" do
    it "should return an array of existing keys" do
      @hash.keys.should == ["foo"]
    end
  end

  describe "#length" do
    it "should return the length of the hash" do
      @hash.length.should == 1
      @hash[:yin] = "yang"
      @hash.length.should == 2
    end
  end

  describe "#merge" do
    it "should return a hash with both the current and provided hash merged together" do
      h = @hash.merge({:yin => "yang"})
      h[:foo].should == "bar"
      h[:yin].should == "yang"
    end
  end

  describe "#merge!" do
    it "should merge the provided hash into the current hash" do
      @hash.merge!(:yin => "yang").eql?("foo" => "bar", "yin" => "yang").should be_true
    end
  end

  describe "#rassoc" do
    it "should return the first key/value pair matching the given value" do
      @hash.rassoc("bar").should == ["foo", "bar"]
    end
    it "should return nil when the provided value is not present" do
      @hash.rassoc("bad").should be_nil
    end
  end

  describe "#reject" do
    it "should return a new hash excluding pairs where block returns true" do
      @hash[:yin] = "yang"
      @hash.reject{|k,v| k == "foo" }.eql?("yin" => "yang").should be_true
    end
  end

  describe "#reject!" do
    it "should remove pairs from hash where block returns true" do
      @hash[:yin] = "yang"
      @hash.reject!{|k,v| k == "foo"}
      @hash.eql?("yin" => "yang").should be_true
    end
    it "should return self if any elements were removed" do
      @hash[:yin] = "yang"
      @hash.reject!{|k,v| k == "foo"}.eql?("yin" => "yang").should be_true
    end
    it "should return nil when no changes were made" do
      @hash.reject!{|k,v| k == "bad"}.should be_nil
    end
  end

  describe "#replace" do
    it "should replace the contents of the hash with the supplied hash" do
      @hash.replace(:yin => "yang")
      @hash.eql?("yin" => "yang").should be_true
    end
  end

  describe "#select" do
    it "should return a hash including only pairs where the block returns true" do
      # Ruby 1.8 actually returns an array, so we cast to array before compare
      @hash[:yin] = "yang"
      r = @hash.select{|k,v| k == "foo"}
      r.to_a.eql?({"foo" => "bar"}.to_a).should be_true
    end
  end

  describe "#select!" do
    it "should keep pairs in hash when block returns true" do
      @hash[:yin] = "yang"
      @hash.select!{|k,v| k == "foo"}
      @hash.eql?("foo" => "bar").should be_true
    end
    it "should return self if any elements were selected" do
      @hash[:yin] = "yang"
      @hash.select!{|k,v| k == "foo"}.eql?("foo" => "bar").should be_true
    end
    it "should return nil when no changes were made" do
      @hash.select!{|k,v| %w{foo yin}.member?(k) }.should be_nil
    end
  end

  describe "#shift" do
    it "should remove and return a key/value pair form the hash" do
      @hash.shift.should == ["foo", "bar"]
      @hash.empty?.should be_true
    end
    it "should return nil if no values are removed" do
      @hash.clear
      @hash.shift.should be_nil
    end
  end

  describe "#save" do
    it "should return true for compatibility" do
      @hash.save.should be_true
    end
  end

  after :each do
    @hash.destroy
  end
end
