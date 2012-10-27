require 'spec_helper'

describe Redis::Types::List do
  before :each do
    $redis.rpush "test", "foo"
    $redis.rpush "test", "bar"
    @a = Redis::Types::List.new "test"
  end

  describe "#+" do
    it "should return a new array containg values from both" do
      v = @a + ["yin", "yang"]
      v.should == %w{foo bar yin yang}
    end
  end
  
  describe "#<<" do
    it "should add values" do
      @a.length.should == 2
      @a << "value"
      @a.length.should == 3
    end
    it "should allow chaining" do
      @a.length.should == 2
      @a << "value1" << "value2"
      @a.length.should == 4
    end
  end

  describe "#<=>" do
    it "should return based on alphabetical order of key for other redis lists" do
      first = Redis::Types::List.new("another_list")
      last  = Redis::Types::List.new("zany_key")
      same  = Redis::Types::List.new("test")
      (@a <=> first).should ==  1
      (@a <=> last ).should == -1
      (@a <=> same ).should ==  0
    end
    it "should return based on array contents when sent an array" do
      (@a <=> %w{foo aar}).should ==  1
      (@a <=> %w{foo zar}).should == -1
      (@a <=> %w{foo bar}).should ==  0
    end
  end

  describe "#[]" do
    it "should return the specified index" do
      @a[1].should == "bar"
    end
    it "should return an array for the specified index and length" do
      @a << "yin" << "yang"
      @a[ 1, 2 ].should == %w{bar yin}
    end
    it "should return an empty array when length is zero" do
      @a[1,0].should === []
    end
    it "should return nil when a negative length is given" do
      @a[1,-1].should be_nil
    end
    it "should return an array that stops at the last element" do
      @a[1,16].should == %W{bar}
    end
    it "should return an array for the specified range" do
      @a[0..1].should == %w{foo bar}
      @a[1..2].should == %w{bar}
      @a[0..-1].should == %w{foo bar}
    end
  end

  describe "#abbrev" do
    it "should provide a hash of abbreviations" do
      require 'abbrev'
      # skip test in jruby 1.6.8 (ruby 1.8 mode) due to bugged strings
      if defined?(RUBY_DESCRIPTION) and RUBY_DESCRIPTION =~ /^jruby 1\.6\.8 \(ruby-1\.8\.7/
        true.should be_true
      else
        @a.abbrev.should == {"fo"=>"foo", "f"=>"foo", "ba"=>"bar", "b"=>"bar", "foo"=>"foo", "bar"=>"bar"}
      end
    end
  end

  describe "#assoc" do
    it "should return the first member array whose first value matches supplied value" do
      t = Redis::Types::List.new
      t << %w{foo bar} << %w{yin yang}
      t.assoc("yin").should == %w{yin yang}
    end
    it "should return nil when the supplied value is not found" do
      t = Redis::Types::List.new
      t << %w{foo bar} << %w{yin yang}
      t.assoc("yang").should be_nil
    end
  end

  describe "#at" do
    it "should provide the value at the specified index" do
      @a.at(0).should == "foo"
      @a.at(1).should == "bar"
    end
    it "should provide a value from the end when a negative index is specified" do
      @a.at(-1).should == "bar"
      @a.at(-2).should == "foo"
    end
  end

  describe "#clear" do
    it "should remove all items from list and return the empty list" do
      a = @a.clear
      @a.length.should == 0
      a.length.should == 0
      @a.should === a
    end
  end

  describe "#each" do
    it "should iterate through the values in order" do
      i = 0
      @a.each do |value|
        value.should == "foo" if i == 0
        value.should == "bar" if i == 1
        i += 1
      end
    end
    it "should yield unmarshalled arbitrary objects" do
      a = Redis::Types::List.new "each_marshal"
      a << TestStruct.new("bar", "yang")
      v = a.pop
      v.foo.should == "bar"
      v.yin.should == "yang"
    end
  end

  describe "#pop" do
    it "should remove and return the last element" do
      @a.pop.should == "bar"
      @a.length.should == 1
    end
    it "should unmarshall arbitrary objects" do
      @a << TestStruct.new("bar", "yang")
      v = @a.pop
      v.foo.should == "bar"
      v.yin.should == "yang"
    end
  end

  describe "#save" do
    it "should persist the array to Redis" do
      @a << "pop"
      @a.save
      a = Redis::Types::List.new "test"
      a.pop.should == "pop"
    end
  end

  after :each do
    $redis.del "test"
  end
end
