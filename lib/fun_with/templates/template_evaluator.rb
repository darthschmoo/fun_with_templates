module FunWith
  module Templates
    class TemplateEvaluator
      attr_reader :content, :vars, :path, :children
      attr_accessor :parent
      TEMPLATE_FILE_REGEX = /\.(fw)?template$/
      VARIABLE_SUBSTITUTION_REGEX = /%(?<num_format>\d+)?(?<var_name>[a-zA-Z][A-Za-z0-9_]*)(?<method_to_call>[a-zA-Z][A-Za-z0-9_])?%/
      VERBOSE = false
      
      # A simple interface for filling in and cloning an entire directory.
      # The entire directory shares a single set of variables... may be made
      # more flexible later, with an ability to specify special behaviors
      # based on file matching regexes?
      #
      # For now you feed the function the template directory, the destination you want it cloned into.
      # The vars is a hash, with symbols as the variable names.  If you declare { :monkey_name => "Bongo" },
      # you can use <%= @monkey_name %> in any of the templates.
      #
      # If a file is named with the '.template' file extension, it will undergo variable substitution.
      # 
      # If a file is named with the '.template_seq' file extension, a sequence of files will be created (not yet implemented)
      # Let's start by supporting a numbered sequence.  The filename of the template should include letters and numbers between
      # %s.  Example:  chapter-%0000chap_count%.markdown.template_seq
      #            ==> chapter-0001.markdown
      #            ==> chapter-0002.markdown
      #            ==> chapter-0003.markdown
      #            ...
      #            ==> chapter-0099.markdown
      #
      #            In this case, :chap_count would be the key in vars.
      
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
      #    vars = {:i => 20} (will generate 1 - 20)
      #    vars = {:i => 0..19} (will generate 0 - 19)
      #    vars = {:i => %w(ocelot mouse kitten puppy velociraptor)}  # @i will be filled in with the given strings.  leading 0s will be ignored.
      #    
      # The directory structure is cloned.
      # 
      # Files named with any other extension will simply be copied as-is.
      def self.evaluate( src, dest, vars = {} )
        puts "self.evaluate( #{src.inspect}, #{dest.inspect}, #{vars.inspect} )"
        self.new( src, vars ).evaluate( dest )
      end
      
      def self.write( src, dest, vars = {} )
        self.new( src, vars ).write( dest )
      end
      
      # source: absolute filepath of the source template
      # dest: absolute filepath of the destination.  The %sequence_variable% must be intact, and the same as the source,
      #       but the overall filename can be different.
      
      
      
      
      
      # # TODO: May be obsolte.  Probably obsolete.
      # # vars: the variables to use on this template.  This must include the :sequence_variable key if it's going to work.
      # def self.evaluate_sequence( source, dest, vars = {} )
      #   # figure out the sequencing variable by analyzing the filename.
      #   seq_varname = dest.basename.match( SEQUENCE_VAR_REGEX )[1]
      #   dest = dest.gsub( TEMPLATE_FILE_REGEX, '' )
      #   
      #   if m = seq_varname.match( /^(0+)/ )
      #     width = m[1].length
      #     seq_varname.gsub!(/^0+/, '')
      #     dest = dest.gsub( SEQUENCE_VAR_REGEX, "%#{seq_varname}%" )
      #   else
      #     width = nil
      #   end
      #   
      #   # find the sequence
      #   seq_values = vars[seq_varname.to_sym]
      #   puts "seq_varname : #{seq_varname.inspect}" if VERBOSE
      #   puts "seq_values  : #{seq_values.inspect}"  if VERBOSE
      #   
      #   case seq_values
      #   when Integer
      #     seq_values = (1..seq_values).to_a
      #   when Range
      #     seq_values = seq_values.to_a
      #   when Array
      #     # Do nothing.  I hope you know what you're doing.
      #   when String
      #     
      #   end
      #   
      #   # execute the template for each of the values in the sequence.
      #   # each time, the variable sequence key is replaced by the specific value
      #   for val in seq_values
      #     val_as_string = (width && val.is_a?(Integer)) ? sprintf("%0#{width}i", val) : val.to_s
      #     dest_for_sequence_item = dest.gsub( "%#{seq_varname}%", val_as_string )
      #     
      #     self.result_to_file( source, dest_for_sequence_item, vars.merge( {seq_varname.to_sym => val} ) )
      #     puts "Sequence: #{dest_for_sequence_item}" if VERBOSE
      #   end
      # end
      
      # content : either a string to be ERB evaluated or a filepath
      # vars    : the variables required by the template you're filling in.
      def initialize( content_or_path, vars = {} )
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
            @children << child
          else
            for narrowed_var_set in combos
              narrowed_var_set.inspect
            
              child = TemplateEvaluator.new( entry, @vars.clone.merge( narrowed_var_set ) )
              @children << child
            end
          end
          
          for child in @children
            child.parent = self
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
      def destination( dest_root = nil )
        dest = dest_root ? dest_root.join( self.relative_path_from_root ) : self.relative_path_from_root
        
        dest = dest.gsub( TEMPLATE_FILE_REGEX, "" )
        FilenameVarData.fill_in_path( dest, parse_filename_vars, @vars )
      end
      
      def each_node_with_destination( dest = :temp, &block )
        dest = FunWith::Files::FilePath.tmpdir if dest == :temp
          
        self.each_node do |node|
          yield [node, node.destination( dest )]
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
          # formerly @template_evaluator_current_content.  Don't know if removing the @ makes a diff.
          template_evaluator_current_content = self.content  # In case someone using the templates uses @content
          template_evaluator_set_local_vars( @vars ) do
            ERB.new( template_evaluator_current_content ).result( binding )
          end
        elsif @path.file?
          # just copy if it's not a template
          @path.read
        end
      rescue Exception => e
        puts "TemplateEvaluator: Exception while evaluating template #{@path}.  Rethrowing."
        raise e
      end
      
      def result_to_file( dest )
        dest = dest.fwf_filepath.expand
        dest.write( self.result )
      end
      
      # if @path is nil, then single file.  The dest is assumed to be the file dest (cannot be a directory).
      # if @path is a directory, then we're copying the whole directory.  Still doing variable substitution on the dest.
      # if @path is a file, decide whether to interpret as a single file or a sequence.
      # def evaluate( dest )
      #   if @path 
      #     if @path.directory?
      #       self.evaluate( dest )
      #     elsif @path.file?
      #       puts "TemplateEvaluator.evaluate( #{dest.inspect} )"
      #       filename_vars_to_substitute = parse_filename_vars
      #       
      #       if filename_vars_to_substitute.fwf_blank?  # don't need to create multiple files for this template.
      #         self.result_to_file( dest )
      #       else
      #       
      #         # How's this need to work?  Every possible combination of items in the sequence?  Should it just do each of the first var it finds,
      #         # substitute the array/sequence for the item in the sequence, and then delegate the result to a new evaluator?
      #         # seems easiest.
      #       
      #         # # detect varsub with multiple entries
      #         # Never mind.  Just going to trust that the user is doing the right thing
      #         # vars_to_sub = filename_vars_to_substitute.select do |var|
      #         #   var = @vars[var.to_sym]
      #         #   var.respond_to?(:each) && var.respond_to?(:length) && !var.is_a?(String)
      #         # end
      #       
      #         puts "VARS TO SUB:  #{vars_to_sub.inspect}"
      #       
      #         array = loop_over_vars( vars_to_sub, @vars )
      #       
      #         for item in array
      #           puts "-------------------"
      #           puts item.inspect
      #         end
      #       
      #       end
      #     else
      #       raise "TemplateEvaluator.evaluate() : What do I do with #{@path.inspect}?"
      #     end
      #   else
      #     self.result_to_file( dest )
      #   end
      # end
      
      
      # def loop_over_vars( filename_vars, template_vars )
      #   return [] if varnames.fwf_blank?
      #   
      #   puts "*******************************************"
      #   puts "In loop_over_vars( #{varnames.inspect}, #{vars} )"
      #   
      #   result = []
      #   filename_var = filename_var.shift
      #   
      #   for loopable_var in template_vars[ filename_var.name ]  # should be some set of variables that can be looped through
      #     narrowed_template_vars = template_vars.clone
      #     
      #     narrowed_val = 
      #     substitute_file_string = 
      #     
      #     
      #     
      #     filename_var.narrow( narrowed_template_vars )
      #     narrowed_template_vars[ filename_var.name ] = filename_var.method_to_call ? loopable_var.send( filename_var.method_to_call ) : loopable_var
      #     
      #     for item in loopable_var
      #       settled_varables[varname] = item
      #       if varnames.fwf_blank?  # we're looking at the last set of variables to settle
      #         result << settled_varables.clone
      #       else
      #         result += loop_over_vars( varnames, settled_vars )
      #       end
      #     end
      #   end
      #   
      #   result
      # end
      
      # if the var found in the filename isn't included in the set of variables given (@vars), no substitution will be performed
      def parse_filename_vars( path = @path )
        var_matches = path.to_s.scan( VARIABLE_SUBSTITUTION_REGEX )
        
        return [] if var_matches.fwf_blank?
        
        var_matches.inject([]) do |memo, var_match|
          # only return the matches where the name of the variable is in @vars
          if @vars.keys.include?( var_match[1].to_sym )
            memo << FilenameVarData.new( var_match[1], var_match[2], var_match[0] )
          end
          
          memo
        end
      end
      
      
      
      
      # def evaluate( dest )
      #   dest = FunWith::Files::FilePath.tmpdir if dest == :temp
      #   raise "#{self.class}.evaluate() : generating a directory cannot replace existing file with a directory" if dest.file?
      #   dest.touch_dir   # create the dir if it doesn't exist
      #   
      #   source_directories, source_files = @path.glob(:all).partition(&:directory?)
      #   
      #   for entry in [source_directories, source_files].flatten   # build directories first
      #     relative_path = entry.relative_path_from( @path )
      #     
      #     entry_dest = self.class.destination_filename( entry, @path, dest, @vars )  # may someday want to do var substitution within filename
      #     
      #     if entry.directory?
      #       entry_dest.touch_dir
      #       puts "Created directory #{entry_dest}/" if VERBOSE
      #     elsif is_template?( entry )
      #       self.class.new( entry, @vars ).evaluate( entry_dest )
      #       puts "Created file #{entry_dest} from template #{relative_path}" if VERBOSE
      #     elsif entry.file?
      #       entry.copy( entry_dest )
      #       puts "Copied file #{relative_path} to #{entry_dest}" if VERBOSE
      #     else
      #       puts "Should never get here."
      #     end
      #   end
      #   
      #   dest
      # end
      
      
      
      
      
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
        obj.respond_to?(:each) && ! obj.is_a?(String)
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