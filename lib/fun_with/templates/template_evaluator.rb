module FunWith
  module Templates
    class TemplateEvaluator
      attr_reader :content, :vars, :path, :children
      attr_accessor :parent
      
      TEMPLATE_FILE_REGEX = /\.(fw)?template$/
      VARIABLE_SUBSTITUTION_REGEX = /%(0+)?([a-zA-Z][A-Za-z0-9_]*)(?:\.([a-zA-Z][A-Za-z0-9_]*))?%/
      VERBOSE = false
      
      # A simple interface for filling in and cloning an entire directory.
      # The entire directory shares a single set of variables... may be made
      # more flexible later, with an ability to specify special behaviors
      # based on file matching regexes?
      # 
      # For now you feed the function the template directory, the destination you want it cloned into.
      # The vars is a hash, with symbols as the variable names.  If you declare { :monkey_name => "Bongo" },
      # you can use <%= @monkey_name %> in any of the templates, and '%monkey_name%' in the filename.
      # 
      # If a file is named with the '.template' or '.fwtemplate' file extension, it will undergo variable substitution.
      # 
      # If the variable is an Array or Range or other enumeratableable object, and the filename has a variable embedded
      # in it, the template will be evaluated once for each item enumerated, leading to multiple destination files.
      # But if the variable name isn't in the filename, the whole enumerable object gets passed in.  I'm not totally 
      # happy with the inconsistency.
      # 
      # Filename variables:
      # 
      # A few examples:  
      #    - %i%  :  filled in.  If the variable :i is enumerable, then the template gets evaluated multiple times
      #    - %character.name%  :  The object { :character => Character.new("barry") } gets .name() called on it.
      #    - %000k%  :  The number gets leading zeros.
      #    - %hello_world%  : You can use underscores.
      # 
      # Example:  chapter-%0000chap_count%.markdown.template_seq
      #            ==> chapter-0001.markdown
      #            ==> chapter-0002.markdown
      #            ==> chapter-0003.markdown
      #            ...
      #            ==> chapter-0099.markdown
      # 
      #            In this case, :chap_count would be the key in vars.
      # 
      #      Example (no leading 0s):  chapter%i%.html.template
      #                                ==> chapter1.html
      #                                ==> chapter2.html
      #                                ==> chapter3.html
      #                                ...
      #                                ==> chapter99.html
      #     
      # The point of the leading zeros is to specify that the file's number will be padded with zeros.
      # 
      # When declaring this in vars, you can use any of the following:
      #    vars = {:i => 0..19} (will generate 0 - 19)
      #    vars = {:i => %w(ocelot mouse kitten puppy velociraptor)}  # @i will be filled in with the given strings.  leading 0s will be ignored.
      #    
      # The directory structure is cloned.
      # 
      # Files named with any other extension will simply be copied as-is.
      def self.write( src, dest, vars = {} )
        self.new( src, vars ).write( dest )
      end
      
      # source: absolute filepath of the source template
      # dest: absolute filepath of the destination.  The %sequence_variable% must be intact, and the same as the source,
      #       but the overall filename can be different.
      # content : either a string to be ERB evaluated or a filepath
      # vars    : the variables required by the template you're filling in.
      def initialize( content_or_path, vars = {} )
        # debugger # if content_or_path =~ /xhtml/
        @vars = vars

        if content_or_path.is_a?( FunWith::Files::FilePath )   #  && content.file?
          @path    = content_or_path
          make_children  # only directly creates first level.  Rest are handled by recursion
        else
          @path = nil
          @content = content_or_path
        end
      end
      
      def make_children
        @children = []
        
        # TODO: Fix fwf so that recursiveness can be turned off.
        if @path.directory?
          child_paths = @path.glob(:all, :recursive => false).select{|entry| entry.dirname == @path}
        elsif parse_filename_vars.fwf_blank? || ! loopable_variables?( parse_filename_vars, @vars ) # The current template is leaf?
          child_paths = []
        else # we need to make the pathname variants
          child_paths = [@path]   
        end
        
        for entry in child_paths
          combos = var_combos( parse_filename_vars( entry ), @vars )
          
          if combos.fwf_blank?   # Then you don't need to go any deeper?
            child = TemplateEvaluator.new( entry, @vars.clone )
            child.parent = self
            @children << child
          else
            for narrowed_var_set in combos
              narrowed_var_set.inspect
            
              child = TemplateEvaluator.new( entry, @vars.clone.merge( narrowed_var_set ) )
              child.parent = self
              @children << child
            end
          end
        end
      end
      
      # given the vars and a list of which entries to loop over
      #
      # Should yield combinations of entries in the multi_entry variables.
      # for example
      # comboize( [ :i, :j, :k], { :i => 0..2, :j => 0..2, :k => 0..2 } )
      # would yield { :i => 0, :j => 0, :k => 0 }
      #        then { :i => 0, :j => 0, :k => 1 }
      #        then { :i => 0, :j => 0, :k => 2 }
      #        then { :i => 0, :j => 1, :k => 0 } ...
      #
      # The results can just be merged into the cloned variable set for a given child.
      def var_combos( var_data, vars, &block )
        return [] if var_data.fwf_blank?
        var_name = var_data.shift
        if var_name.nil?
          raise "Recursed too far!"
        elsif var_data.fwf_blank?    # last variable in the list, so start yielding
          combos = []
          loop_over( vars[ var_name.name ] ) do |item|
            hash = { var_name.name => item }
            combos << hash
          end
          return combos
        else                         # recurse into other variables
          # Order doesn't matter, so take the results of the next recursion, pop from the front,
          # create a subarray with the variations, and push to the back.  Stop when the key is found.
          partial_combos = var_combos( var_data, vars )
          
          until partial_combos.length == 0 || partial_combos.first.keys.include?( var_name.name )
            hash = partial_combos.shift
            filled_combos = []
            
            loop_over( vars[var_name.name] ) do |item|
              h = hash.clone
              h[var_name.name] = item
              filled_combos << h
            end
            
            partial_combos += filled_combos
          end
          
          return partial_combos
        end
      end
      
      
      def src_root
        self.parent ? self.parent.src_root : @path
      end
      
      def relative_path_from_root
        @path.relative_path_from( self.src_root )
      end
      
      def each_node( &block )
        yield self

        for child in self.children
          child.each_node do |node|
            yield node
          end
        end
      end


      # if no destination root is given, then a relative path from the src_root is given
      # if this calculated dest is a directory, while the template @path is a file, then
      # the template's basename is appended to the dest and filled in
      def destination( dest_root = nil )
        dest = dest_root ? dest_root.join( self.relative_path_from_root ) : self.relative_path_from_root
        
        dest = dest.join( @path.basename ) if dest.directory? && @path.file?
          
        dest = dest.gsub( TEMPLATE_FILE_REGEX, "" )
        FilenameVarData.fill_in_path( dest, parse_filename_vars, @vars )
      end
      
      def each_node_with_destination( dest_root = :temp, &block )
        dest_root = FunWith::Files::FilePath.tmpdir if dest_root == :temp
          
        self.each_node do |node|
          dst = node.destination( dest_root )
           if dst       # if the filename needs variable replacing
             yield [node, dst]
           else   
             warn( "Warning: file #{node.path} was not returned.") if FunWith::Templates.gem_verbose?
           end
        end
      end
      
      def write( dest = :temp )
        dest = FunWith::Files::FilePath.tmpdir if dest == :temp
        
        self.each_node_with_destination( dest ) do |node, destination|
          if node.path.directory?
            destination.touch_dir
          else
            destination.write( node.result )
          end
        end
        
        dest
      end
      
      def content
        @content || ( ( @path && @path.file?) ? @path.read : "ERROR: 'content() meaningless for directory" )
      end

      # only called on leaf/files
      def result
        if @path.nil? || is_template?( @path )
          begin
            # formerly @template_evaluator_current_content.  Don't know if removing the @ makes a diff.
            template_evaluator_current_content = self.content  # In case someone using the templates uses @content
            template_evaluator_set_local_vars( @vars ) do
              ERB.new( template_evaluator_current_content ).result( binding )
            end
          rescue Exception => e
            warn( "Template #{ @path } could not be filled in properly (using vars: #{@vars.inspect}).  Returning error as result." )
            result = ["FunWith::Templates::TemplateEvaluator ERROR"]
            result << ""
            result << "path: #{@path}"
            result << ""
            result << "vars: #{@vars.inspect}"
            result << ""
            result << "#{e.class}: #{e.message}"
            result += e.backtrace.map{|line| "\t#{line}" }
            
            FunWith::Templates.say_if_verbose( result.join("\n") )
            result.join("\n")
          end
        elsif @path.file?
          # just copy if it's not a template
          @path.read
        end
      end
      
      def result_to_file( dest )
        dest = dest.fwf_filepath.expand
        dest.write( self.result )
      end
      
      # if the var found in the filename isn't included in the set of variables given (@vars), no substitution will be performed
      def parse_filename_vars( path = @path )
        var_matches = path.scan( VARIABLE_SUBSTITUTION_REGEX )
        
        return [] if var_matches.fwf_blank?
        
        var_matches.inject([]) do |memo, var_match|
          # only return the matches where the name of the variable is in @vars
          if @vars.keys.include?( var_match[1].to_sym )
            memo << FilenameVarData.new( var_match[1], var_match[2], var_match[0] )
          end
          
          memo
        end
      end
      
      
      # src: Either a file to be read, or a string
      # dst: An output file (exists or not, will be overwritten)
      # vars: A hash: { :var1 => "Value 1", :var2 => "Value 2"}
      # In the template, these can be accessed in the ERB way:
      # <%= @var1 %>, <%= @var2 %>
      def self.result_to_file( src, dst, vars = {} )
        dst = dst.join( src.basename ) if dst.directory?
        
        self.new( src, vars ).result_to_file( dst )
      end
    
      def self.destination_filename( src_file, src_root, dest_root, vars )
        relative_path = src_file.relative_path_from( src_root ).gsub( TEMPLATE_FILE_REGEX, "" )
        dest = dest_root.join( relative_path )
      end
      
      def is_template?( filename )
        !!((filename) =~ TEMPLATE_FILE_REGEX )
      end
      
      def loopable_object?( obj )
        obj.is_a?( Array ) || obj.is_a?( Range )
        # obj.respond_to?(:each) && !obj.is_a?(String) && !obj.is_a?(Hash)
      end
      
      def loopable_variables?( var_info, vars )
        var_info.map(&:name).detect{ |name| loopable_object?( vars[name]) }
      end
      
      def loop_over( var, &block )
        var = [var] unless loopable_object?( var )
        var.each(&block)
      end
    end
  end
end