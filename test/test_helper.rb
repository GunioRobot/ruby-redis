require 'rubygems'
require 'minitest/autorun'

# helpers
Dir.glob(File.expand_path('**/*_helper.rb', File.dirname(__FILE__))).each {|f| require f}

# run all
if $0 == __FILE__
  Dir.glob(File.expand_path('**/*_test.rb', File.dirname(__FILE__))).each {|f| require f}
end
