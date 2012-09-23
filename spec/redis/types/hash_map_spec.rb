require 'spec_helper'

describe "Redis::Types::Hash" do
  before :each do
    @hash = Redis::Types::Hash.new("test")
    @hash[:foo] = "bar"
    @hash.save
  end

  # ==============================================
  # `Hash` specific methods
  # ==============================================

  describe "#new" do
    it "should create an empty hash by default" do
      Redis::Types::Hash.new("foo").should be_empty
    end
    it "should generate a key if one is not provided" do
      Redis::Types::Hash.new.key.should_not be_nil
    end
    it "should open an existing hash when provided a key" do
      hash = Redis::Types::Hash.new("test")
      hash[:foo].should == "bar"
    end
    it "should allow the key to be provided in option hash" do
      hash = Redis::Types::Hash.new(:key => :test)
      hash[:foo].should == "bar"
    end
    it "should merge values when data is provided in option hash" do
      hash = Redis::Types::Hash.new("test", :data => {:yin => "yang"})
      hash[:foo].should == "bar"
      hash[:yin].should == "yang"
    end
  end

  describe "#save" do
    it "should cause the hash to persist" do
      hash = Redis::Types::Hash.new("foo", :data => {:key => "value"})
      $redis.hgetall("foo").should == {}
      hash.save
      $redis.hgetall("foo").should == {"key" => "value"}
      hash.destroy
    end
    context "with replace strategy" do
      it "should overwrite concurrent changes made to the hash" do
        hash = Redis::Types::Hash.new "test", :strategy => :replace
        @hash[:foo] = "something else"
        @hash[:yin] = "yang"
        @hash.save
        $redis.hget("test", "yin").should == "yang"
        hash.save
        $redis.hget("test", "yin").should be_nil
        $redis.hget("test", "foo").should == "bar"
      end
    end
  end

  describe "#destroy" do
    it "should cause the hash to be deleted" do
      $redis.hgetall("test").should == {"foo" => "bar"}
      @hash.destroy
      $redis.hgetall("test").should == {}
    end
  end

  describe "#reload" do
    it "should cause values added to the hash since loading to load" do
      $redis.mapped_hmset("test", {"yin" => "yang"})
      @hash[:yin].should be_nil
      @hash.reload
      @hash[:yin].should == "yang"
    end
  end

  describe "#strategy" do
    it "should default to :replace" do
      @hash.strategy.should == "Replace"
    end
  end

  # ==============================================
  # Strategy specs
  # ==============================================

  # merge strategy
  context ":merge strategy" do
    before :each do
      @hash = Redis::Types::Hash.new( @hash.key, :strategy => :merge )
    end
    describe "#changes" do
      it "should contain recently added keys" do
        @hash[:yin] = "yang"
        @hash.changes[:yin].should == [nil, "yang"]
      end
      it "should contain changed keys" do
        @hash[:foo] = "something else"
        @hash.changes[:foo].should == ["bar", "something else"]
      end
      it "should contain deleted keys" do
        @hash.delete(:foo)
        @hash.changes[:foo].should == ["bar", nil]
      end
      it "should not contain unchanged keys" do
        @hash.changes[:foo].should be_nil
      end
    end

    describe "#added" do
      it "should contain recently added keys" do
        @hash[:yin] = "yang"
        @hash.added.member?("yin").should be_true
      end
      it "should not contain changed keys" do
        @hash[:foo] = "something else"
        @hash.added.empty?.should be_true
      end
    end

    describe "#changed" do
      it "should contain recently changed keys" do
        @hash[:foo] = "something else"
        @hash.changed.member?("foo").should be_true
      end
      it "should not contain recently added keys" do
        @hash[:yin] = "yang"
        @hash.changed.empty?.should be_true
      end
      it "should not contain recently deleted keys" do
        @hash.delete(:foo)
        @hash.changed.empty?.should be_true
      end
    end

    describe "#deleted" do
      it "should contain recently removed keys" do
        @hash.delete(:foo)
        @hash.deleted.member?("foo").should be_true
      end
      it "should not contain recently changed keys" do
        @hash[:foo] = "something else"
        @hash.deleted.empty?.should be_true
      end
    end

    describe "#save" do
      it "should successfully add and delete values added/removed" do
        @hash[:yin] = "yang"
        @hash[:key] = "value"
        @hash.delete(:foo)
        @hash.save
        hash = Redis::Types::Hash.new( @hash.key, :strategy => :merge )
        hash[:yin].should == "yang"
        hash[:foo].should be_nil
      end
      it "should incorporate concurrently made changes" do
        concurrent = Redis::Types::Hash.new( @hash.key, :strategy => :merge )
        concurrent[:yin] = "yang"
        concurrent.delete(:foo)
        @hash[:yin].should be_nil
        @hash[:foo].should == "bar"
        @hash[:key] = "value"
        @hash[:yin] = "something"
        @hash[:foo] = "baz"
        concurrent.save
        @hash.save
        @hash[:yin].should == "yang"
        @hash[:foo].should be_nil
        @hash[:key].should == "value"
      end
    end
  end

  # change strategy
  context ":change strategy" do
    before :each do
      @hash = Redis::Types::Hash.new( "test", :strategy => :change )
    end
    describe "#save" do
      it "should incorporate concurrently made changes, unless changed in current" do
        concurrent = Redis::Types::Hash.new( "test", :strategy => :change )
        concurrent.delete(:foo)
        concurrent[:yin] = "yang"
        concurrent[:key] = "value"
        concurrent.save
        @hash[:key] = "something"
        @hash.save
        @hash[:yin].should == "yang"
        @hash[:foo].should be_nil
        @hash[:key].should == "something"
      end
    end
  end

  # lock strategy
  context ":lock strategy" do
    before :each do
      @hash = Redis::Types::Hash.new( "test", :strategy => :lock )
    end
    describe "[]=" do
      it "should raise an error when called before being locked" do
        expect{ @hash[:yin] = "yang" }.to raise_error(Redis::Types::Hash::Strategies::Lock::Error)
      end
      it "should allow changes after being locked" do
        @hash.lock
        @hash[:yin] = "yang"
        @hash[:yin].should == "yang"
      end
    end
    describe "#save" do
      it "should raise error when called without being locked" do
        expect{ @hash.save }.to raise_error(Redis::Types::Hash::Strategies::Lock::Error)
      end
      it "should save changes after being locked" do
        @hash.lock
        @hash[:yin] = "yang"
        @hash.save
        $redis.hget("test", "foo").should == "bar"
        $redis.hget("test", "yin").should == "yang"
      end
      it "should raise error when another hash has a lock" do
        concurrent = Redis::Types::Hash.new("test", :strategy => :lock)
        concurrent.lock
        expect{ @hash.lock }.to raise_error(Redis::Types::Hash::Strategies::Lock::Error)
      end
      it "should overwrite incorporate changes made before being locked" do
        concurrent = Redis::Types::Hash.new("test", :strategy => :lock)
        concurrent.lock
        concurrent[:yin] = "yang"
        concurrent.save
        @hash.lock
        @hash[:yin].should == "yang"
      end
    end
  end
  
  # ==============================================
  # Typical `Hash` methods
  # ==============================================

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
      Redis::Types::Hash.new("test")[:foo].should be_nil
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

  describe "#key" do
    it "should return the redis key when no argument is supplied" do
      @hash.key.should == "test"
    end
    it "should return the value for a key when a key is supplied" do
      @hash.key(:foo).should == "bar"
    end
    it "should return nil when a non-existent key is supplied" do
      @hash.key(:bad).should be_nil
    end
  end

  # ==============================================
  # Marshaling tests
  # ==============================================

  describe "marshalling" do
    it "should marshal hash values properly" do
      @hash[:key] = {:foo => "bar"}
      @hash.save
      hash = Redis::Types.load "test", :type => :hash_map
      hash[:key][:foo].should == "bar"
    end
    it "should marshal arrays properly" do
      @hash[:key] = %w{foo bar}
      @hash.save
      hash = Redis::Types.load "test"
      hash[:key].should == %w{foo bar}
    end
    it "should marshal integers properly" do
      @hash[:key] = 123
      @hash.save
      hash = Redis::Types.load "test"
      hash[:key].should === 123
    end
    it "should marshal floats properly" do
      @hash[:key] = 1.23
      @hash.save
      hash = Redis::Types.load "test"
      hash[:key].should === 1.23
    end
    it "should marshal user objects properly" do
      class TestObject
        attr_accessor :test
      end
      t = TestObject.new
      t.test = "foobar"
      @hash[:key] = t
      @hash.save
      hash = Redis::Types.load "test"
      hash[:key].test.should == t.test
    end
  end

  after :each do
    @hash.destroy
  end
end
