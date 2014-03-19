module FunWith
  module Templates
    class TemplateEvaluator
      
      attr_reader :content, :vars, :result
      
      SEQUENCE_VAR_REGEX = /%(\w+)%/
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
      def self.evaluate_dir( src, dest, vars = {} )
        dest = FunWith::Files::FilePath.tmpdir if dest == :temp
        dest.touch_dir   # create the dir if it doesn't exist
        
        source_directories, source_files = src.glob(:all).partition(&:directory?)
        
        for entry in [source_directories, source_files].flatten   # build directories first
          relative_path = entry.relative_path_from( src )
          
          entry_dest = destination_filename( entry, src, dest, vars )  # may someday want to do var substitution within filename
          
          if entry.directory?
            entry_dest.touch_dir
            puts "Created directory #{entry_dest}/" if VERBOSE
          elsif is_template?( entry )
            self.result_to_file( entry, entry_dest, vars )
            puts "Created file #{entry_dest} from template #{relative_path}" if VERBOSE
          elsif is_template_sequence?( entry )
            self.evaluate_sequence( entry, entry_dest, vars )
          elsif entry.file?
            FileUtils.cp( entry, entry_dest )
            puts "Copied file #{relative_path} to #{entry_dest}" if VERBOSE
          end
        end
        
        dest
      end
      
      # source: absolute filepath of the source template
      # dest: absolute filepath of the destination.  The %sequence_variable% must be intact, and the same as the source,
      #       but the overall filename can be different.
      # vars: the variables to use on this template.  This must include the :sequence_variable key if it's going to work.
      def self.evaluate_sequence( source, dest, vars = {} )
        # figure out the sequencing variable by analyzing the filename.
        seq_varname = dest.basename.match( SEQUENCE_VAR_REGEX )[1]
        dest = dest.gsub( /\.template(_seq)?$/, '' )
        
        if m = seq_varname.match( /^(0+)/ )
          width = m[1].length
          seq_varname.gsub!(/^0+/, '')
          dest = dest.gsub( SEQUENCE_VAR_REGEX, "%#{seq_varname}%" )
        else
          width = nil
        end
        
        # find the sequence
        seq_values = vars[seq_varname.to_sym]
        puts "seq_varname : #{seq_varname.inspect}" if VERBOSE
        puts "seq_values  : #{seq_values.inspect}"  if VERBOSE
        
        debugger if seq_values.nil?
        case seq_values
        when Integer
          seq_values = (1..seq_values).to_a
        when Range
          seq_values = seq_values.to_a
        when Array
          # Do nothing.  I hope you know what you're doing.
        end
        
        # execute the template for each of the values in the sequence.
        # each time, the variable sequence key is replaced by the specific value
        for val in seq_values
          val_as_string = (width && val.is_a?(Integer)) ? sprintf("%0#{width}i", val) : val.to_s
          dest_for_sequence_item = dest.gsub( "%#{seq_varname}%", val_as_string )
          
          self.result_to_file( source, dest_for_sequence_item, vars.merge( {seq_varname.to_sym => val} ) )
          puts "Sequence: #{dest_for_sequence_item}" if VERBOSE
        end
      end
      
      # content : either a string to be ERB evaluated or a filepath
      # vars    : the variables required by the template you're filling in.
      def initialize( content, vars = {} )
        if content.is_a?( FunWith::Files::FilePath ) && content.file?
          @path    = content
          @content = content.read
        else
          @path = nil
          @content = content.to_s
        end
        
        @vars = vars
        
        begin
          @template_evaluator_current_content = @content  # In case someone using the templates uses @content
          @result = template_evaluator_set_local_vars( @vars ) do
            ERB.new( @template_evaluator_current_content ).result( binding )
          end
        rescue Exception => e
          puts "TemplateEvaluator: Exception while evaluating template #{@path}.  Rethrowing."
          raise e
        end
        
        self
      end
      
      
      def result_to_file( dest )
        dest = dest.fwf_filepath.expand
        dest.write( self.result )
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
        relative_path = src_file.relative_path_from( src_root ).gsub( /\.template$/, "" )
        dest = dest_root.join( relative_path )
      end
      
      def self.is_template?( filename )
        !!(filename =~ /\.template$/)
      end
      
      def self.is_template_sequence?( filename )
        !!(filename =~ SEQUENCE_VAR_REGEX )
      end
    end
  end
end