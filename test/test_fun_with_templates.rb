require 'helper'

class TestFunWithTemplates < FunWith::Templates::TestCase
  context "basics" do
    should "accept the reality of FunWith::Templates" do
      assert defined?( FunWith ), "FunWith module not defined"
      assert defined?( FunWith::Templates ), "FunWith::Templates not defined."
    end
  
    should "properly root FunWith::Templates" do
      assert FunWith::Templates.respond_to?(:root)
      assert_equal FunWith::Templates.root, __FILE__.fwf_filepath.dirname.up
    end
  
    should "properly version FunWith::Templates" do
      assert FunWith::Templates.respond_to?( :version )
      assert FunWith::Templates.root( "VERSION" ).file?
      assert_equal FunWith::Templates.root( "VERSION" ).read, FunWith::Templates.version.to_s 
    end
  end
end
