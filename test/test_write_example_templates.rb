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
        puts "removing temp directory #{@dest}" if TemplateEvaluator::VERBOSE
        FileUtils.rm_rf( @dest )
      end
    end

    should "validate results of template00" do
      vars =  { :module => "Racer", 
                :class => "Car", 
                :args => ["size", "color", "speed"],
                :i => (0..20),
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
      
      @dest = TemplateEvaluator.write( @template_00, :temp, vars )
      assert @dest.directory?
      assert @dest.join( "dir", "subdir" ).directory?
      a_rb = @dest.join( "a.rb" )
      assert a_rb.file?
      assert_equal 1, a_rb.grep( /size \* color \* speed/ ).length
      style_css = @dest.join( "dir", "subdir", "style.css" )
      assert style_css.file?
      assert_equal 1, style_css.grep( /font-weight/ ).length
      seqdir = @dest.join("seqfiles")
      assert_equal 21, seqdir.glob("page????.html").length
      assert_equal 5, seqdir.glob("page_about_*.html").length
      assert_equal 3, seqdir.join("page_about_mollusc.html").grep(/mollusc/).length
      assert_equal 1, seqdir.join("page_about_cat.html").grep(/tailtwitchy/).length
    end
    
    # should "build templates/epf" do
    #       vars = {
    #         :book => {
    #           :title => "The Dawning of the Elluini",
    #           :author => "Manchester Von Spittleman",
    #           :license => "Creative Commons",
    #           :publisher => "PUBLISHER NAME",
    #           :original_publication => "2014-01-01"
    #         },
    # 
    #         :name => "Wilford Brimley",
    #         :age => "Older than time itself",
    #         :summary => "The Faceless Old Man Who Secretly Lives In Your Home",
    #         :description => "Gentle, wizened, concerned about your bowel movements.",
    #         :chapter_count => 20,
    #         
    #         :git => {
    #           :repo => "/home/barry/git/the_dawning_of_the_elluini.epubforge.git",
    #           :remote_host => "m.slashdot.org",
    #           :remote_user => "barry",
    #           :repo_id     => "36ce67680bbf6fc4d64741cbc3980fa5"
    #         }
    #       }
    #       
    #       dest = FunWith::Templates::TemplateEvaluator.write( @template_epf, :temp, vars )
    #       
    #       afterword = dest.join("book", "afterword.markdown")
    #       assert afterword.file?
    #       
    #       ch20 = dest.join( "book", "chapter-0020.markdown" )
    #       assert ch20.file?
    #       assert_equal 1, ch20.grep( /^Chapter 20$/ ).length
    #       
    #       cover_page = dest.join( "book", "cover.xhtml" )
    #       assert cover_page.file?
    #       assert_equal 2, cover_page.grep( /Spittleman/ ).length
    #       
    #       config = dest.join( "settings", "config.rb" )
    #       assert config.file?
    #       
    #       assert_equal 1, config.grep( /36ce67/ ).length
    #       
    #       notes_css = dest.join( "notes", "stylesheets", "stylesheet.css" )
    #       assert notes_css.file?
    #       refute notes_css.empty?
    #     end
    #     
    #     should "build template_03, with multiple filename variables" do
    #       vars = { :i => 0..1, :j => 0..1, :k => 0..1 }
    #       
    #       dest = FunWith::Templates::TemplateEvaluator.write( @template_03, :temp, vars )
    #       
    #       entries = dest.glob( :ext => :html )
    #       
    #       for entry in entries
    #         assert entry.file?
    #       end
    #       assert_equal( 8, dest.glob( :ext => :html ).length )
    #     end
  end
end
