require 'helper'

class TestFunWithTemplates < FunWith::Templates::TestCase
  context "run test templates and validate results" do
    setup do
      @templates_dir = FunWith::Templates.root("test", "templates")
      @templates_dir.glob("*").select(&:directory?).each do |path|
        instance_variable_set( "@template#{path.basename}", path )
      end
      
      assert( @template00.is_a?( FunWith::Files::FilePath ) )
      assert( @template01.is_a?( FunWith::Files::FilePath ) )

      @dest = nil
    end
    
    teardown do
      if @dest.is_a?(FunWith::Files::FilePath) && @dest.directory?
        puts "removing temp directory #{@dest}" if TemplateEvaluator::VERBOSE
        FileUtils.rm_rf( @dest )
      end
    end

    should "validate results of template00" do
      @dest = TemplateEvaluator.eval_dir( @template00, :temp, 
        { :module => "Racer", 
          :class => "Car", 
          :args => ["size", "color", "speed"],
          :i => 20,
          :j => (0..19),
          :critter_name => %w(wombat mollusc squid cat gerbil) 
        } 
      )
      assert @dest.join( "dir", "subdir" ).directory?
      
      a_rb = @dest.join( "a.rb" )
      assert a_rb.file?
      assert_equal 1, a_rb.grep( /size \* color \* speed/ ).length
      style_css = @dest.join( "dir", "subdir", "style.css" )
      assert style_css.file?
      assert_equal 1, style_css.grep( /font-weight/ ).length
      seqdir = @dest.join("seqfiles")
      assert_equal 20, seqdir.glob("page????.html").length
      assert_equal 5, seqdir.glob("page_about_*.html").length
      assert_equal 2, seqdir.join("page_about_mollusc.html").grep(/mollusc/).length
    end
    
    # should "validate results of template01" do
    #   dest = FunWith::Templates::TemplateEvaluator.eval_dir( @template01, :temp, {} )
    #   flunk
    # end
  end
end
