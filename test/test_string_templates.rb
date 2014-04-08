require 'helper'

class TestStringTemplates < FunWith::Templates::TestCase
  context "testing template_handler" do
    should "evaluate erb in a string" do
      sample = "(<%= Time.now %>): <%= @var_is_set %>"
      result = FunWith::Templates::TemplateEvaluator.new( sample, var_is_set: "true" ).result
    
      assert_match /true/, result
      time_string = /\((.*)\)/.match(result)[1]
      assert_kind_of Time, Time.parse( time_string )
    end
  end
end