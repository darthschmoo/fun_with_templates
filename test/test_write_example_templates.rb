require 'helper'

class String
  def epf_underscorize
    self.downcase.gsub(/\s+/,"_").gsub(/[\W]/,"")
  end
end

class TestFunWithTemplates < FunWith::Templates::TestCase
  context "run test templates and validate results" do
    setup do
      @templates_dir = FunWith::Templates.root("test", "templates")
      @templates_dir.glob("*").select(&:directory?).each do |path|
        instance_variable_set( "@template_#{path.basename}", path )
      end
      
      assert( @template_00.is_a?( FunWith::Files::FilePath ) )
      assert( @template_01.is_a?( FunWith::Files::FilePath ) )
      assert( @template_02.is_a?( FunWith::Files::FilePath ) )
      assert( @template_03.is_a?( FunWith::Files::FilePath ) )
      assert( @template_epf.is_a?( FunWith::Files::FilePath ) )

      @dest = nil
    end
    
    teardown do
      if @dest.is_a?(FunWith::Files::FilePath) && @dest.directory?
        puts "removing temp directory #{@dest}" if FunWith::Templates::TemplateEvaluator::VERBOSE
        FileUtils.rm_rf( @dest )
      end
    end

    should "validate results of template00" do
      vars =  { :module => "Racer", 
                :class => "Car", 
                :args => ["size", "color", "speed"],
                :i => (1..20),
                :j => (0..19),
                :critter_name => %w(wombat mollusc squid cat gerbil),
                :critters => {
                  "wombat"  => { :attributes => ["cunning", "lycanthropean"] },
                  "mollusc" => { :attributes => ["edible", "seaworthy"] },
                  "squid"   => { :attributes => ["multifaceted", "multitentacled"] },
                  "cat"     => { :attributes => ["glorious", "tailtwitchy"] },
                  "gerbil"  => { :attributes => ["potato-shaped", "nervous"] }
                }
              } 
      
      @dest = FunWith::Templates::TemplateEvaluator.write( @template_00, :temp, vars )
      assert @dest.directory?
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
      assert_equal 3, seqdir.join("page_about_mollusc.html").grep(/mollusc/).length
      assert_equal 1, seqdir.join("page_about_cat.html").grep(/tailtwitchy/).length
      assert_equal 1, seqdir.join("page_about_cat.html").grep(/glorious/).length
      assert_file_contents seqdir.join("page_about_cat.html"), /tailtwitchy/
      assert_file_contents seqdir.join("page_about_cat.html"), /glorious/
    end
    
    should "validate results of template_01" do
      vars = { :string => %w(1 10 100 1000) }

      @dest = FunWith::Templates::TemplateEvaluator.write( @template_01, :temp, vars )
      
      assert_equal( 12, @dest.glob(:all).length )
      
      for str in vars[:string]
        txt = @dest.join( str.length.to_s, "#{str}-#{str.length}.txt" )
        no_template = @dest.join( str.length.to_s, "#{str}-#{str.length}.nontemplate" )
        assert_file txt
        assert_file no_template
        assert_file_contents no_template, /Some strings have/
        assert_file_contents txt, "string #{str} has length #{str.length}"
      end
    end
    
    should "build templates/epf" do
      vars = epf_template_vars
      dest = FunWith::Templates::TemplateEvaluator.write( @template_epf, :temp, vars )
      
      afterword = dest.join("book", "afterword.markdown")
      assert_file afterword
      
      
      ch20 = dest.join( "book", "chapter-0020.markdown" )
      assert_file ch20
      assert_equal 1, ch20.grep( /^Chapter 20$/ ).length
      
      ch01 = dest.join( "book", "chapter-0001.markdown" )
      assert_file ch01
      assert_equal 1, ch01.grep( /^Chapter 1$/ ).length

      cover_page = dest.join( "book", "cover.xhtml" )
      assert_file cover_page
      assert_equal 2, cover_page.grep( /Spittleman/ ).length
      
      config = dest.join( "settings", "config.rb" )
      assert config.file?
      
      assert_equal 1, config.grep( /36ce67/ ).length
      
      notes_css = dest.join( "notes", "stylesheets", "stylesheet.css" )
      assert_file_not_empty notes_css
    end
    
    should "skip a file in templates/epf without character data" do
      vars = epf_template_vars
      vars[:character] = nil
      dest = FunWith::Templates::TemplateEvaluator.write( @template_epf, :temp, vars )
      
      assert_equal 0, dest.join("notes").glob("character.*.markdown").length
    end
    
    
    should "build template_03, with multiple filename variables" do
      vars = { :i => 0..1, :j => 0..1, :k => 0..1 }
      
      dest = FunWith::Templates::TemplateEvaluator.write( @template_03, :temp, vars )
      
      entries = dest.glob( "coordinates.*.html" )
      
      for entry in entries
        assert_file entry
      end
      assert_equal( 8, dest.glob( "coordinates.*.html" ).length )
      
      index = dest.join( "index.html" )
      assert_equal( 8, index.grep(/<li>/).length )
      
      for combo in [ [0,0,0], [0,0,1], [0,1,0], [0,1,1], [1,0,0], [1,0,1], [1,1,0], [1,1,1] ]
        fil = dest.join("coordinates.#{combo[0]}-#{combo[1]}-#{combo[2]}.html")
        assert_file fil
        assert_equal( 2, fil.grep( /\(#{combo[0]}, #{combo[1]}, #{combo[2]}\)/ ).length )
        
        pyfile = dest.join( "dir000#{combo[0]}", "dir000#{combo[1]}", "file000#{combo[2]}.py" )
        assert_file pyfile
        assert_equal 1, pyfile.grep( /#{combo[0]}-#{combo[1]}-#{combo[2]}/ ).length
      end
    end
  end
end
