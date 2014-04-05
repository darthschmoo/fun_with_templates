require 'helper'

class TestFilenameVarData < FunWith::Templates::TestCase
  context "testing filename substitution" do
    should "fill in filename" do
      filename = "hello-%name%.html"
      var_data = FilenameVarData.new( :name )
      sub = "barry"
      
      filename = var_data.fill_in_path( filename, sub )
      
      assert_equal "hello-barry.html", filename      
    end
    
    should "fill in filename via callable method" do
      filename = "hello-%person.name%.html"
      var_data = FilenameVarData.new( :person, :name )
      mod = Module.new do
        def name
          "barry"
        end
      end
      
      sub = Object.new.extend( mod )
      
      filename = var_data.fill_in_path( filename, sub )
      assert_equal "hello-barry.html", filename
    end
    
    should "fill in filename via hash key" do
      filename = "hello-%person.first_name%_%person.last_name%.html"
      var_data1 = FilenameVarData.new( :person, :first_name )
      var_data2 = FilenameVarData.new( :person, :last_name )
      person      = { :first_name => "barry", :last_name => "wendell" }
      
      filename = var_data1.fill_in_path( filename, person )
      filename = var_data2.fill_in_path( filename, person )
      
      assert_equal "hello-barry_wendell.html", filename
    end

    should "fill in multiple variables" do
      filename = "coordinates-%i%-%j%-%k%.html"
      
      var_data = [ FilenameVarData.new(:i), FilenameVarData.new(:j), FilenameVarData.new(:k) ]
      filename = FilenameVarData.fill_in_path( filename, var_data, {:i => 3, :j => 2, :k => 1} )
      
      assert_equal( "coordinates-3-2-1.html", filename )
    end
  end
end