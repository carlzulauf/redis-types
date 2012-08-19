$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'
require 'securerandom'
require 'redis/types'

$redis = Redis.current = Redis::Namespace.new( SecureRandom.hex )
