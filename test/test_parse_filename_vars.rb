require 'helper'

class TestParseFilenameVars < FunWith::Templates::TestCase
  context "parsing filename vars" do
    setup do
    end
    
    should "successfully parse" do
      vars = { :chapter => {:number => 3, :title => "Brokeback Fountain"}}
      @template = FunWith::Templates::TemplateEvaluator.new( nil, vars )
      assert_kind_of FunWith::Templates::TemplateEvaluator, @template
      num, title = @template.parse_filename_vars("chap-%0000chapter.number%-%chapter.title%.html")
      assert_not_nil num
      assert_not_nil title
      assert_equal "0000", num.num_format
      assert_equal :chapter, num.name
      assert_equal :number, num.method_to_call
      
      assert_equal :chapter, title.name
      assert_equal :title, title.method_to_call
      assert_nil   title.num_format

    end
  end
end