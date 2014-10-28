require 'simplecov'
SimpleCov.start

require 'lzop-file'

RSpec.configure do |config|
  config.color = true
  config.mock_with :rspec
end
