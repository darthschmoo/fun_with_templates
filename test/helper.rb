require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'fun_with_templates'

class Test::Unit::TestCase
end

class FunWith::Templates::TestCase < Test::Unit::TestCase
  include FunWith::Templates
  include FunWith::Testing::Assertions::Basics
  include FunWith::Testing::Assertions::FunWithFiles  
end