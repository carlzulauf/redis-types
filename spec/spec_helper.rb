$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'securerandom'
require 'redis/types'
begin
  require 'pry'
rescue; end

$redis = Redis.current = Redis::Namespace.new( SecureRandom.hex )
unless defined?(TestStruct)
  TestStruct = Struct.new(:foo, :yin)
end
