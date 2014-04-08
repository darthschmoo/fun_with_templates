require 'rubygems'
require 'bundler'
require 'debugger'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end

require 'shoulda'
require 'fun_with_templates'
require 'fun_with_testing'

class FunWith::Templates::TestCase < FunWith::Testing::TestCase
  gem_to_test( FunWith::Templates )
  
  FunWith::Templates.gem_test_mode = true
  FunWith::Templates.gem_verbose = false
  
  # include FunWith::Templates
  include FunWith::Testing::Assertions::Basics
  include FunWith::Testing::Assertions::FunWithFiles  

  def epf_template_vars( overrides = {} )
    vars = {
      :book => {
        :title => "The Dawning of the Elluini",
        :author => "Manchester Von Spittleman",
        :license => "Creative Commons",
        :publisher => "PUBLISHER NAME",
        :original_publication => "2014-01-01"
      },

      :character => {
        :name => "Wilford Brimley",
        :name_for_file => "wilford_brimley",
        :age => "Older than time itself",
        :summary => "The Faceless Old Man Who Secretly Lives In Your Home",
        :description => "Gentle, wizened, concerned about your bowel movements."
      },
      
      :chapter => (1..20),
      
      :git => {
        :repo => "/home/barry/git/the_dawning_of_the_elluini.epubforge.git",
        :remote_host => "m.slashdot.org",
        :remote_user => "barry",
        :repo_id     => "36ce67680bbf6fc4d64741cbc3980fa5"
      }
    }
    
    vars.merge( overrides )
  end
end