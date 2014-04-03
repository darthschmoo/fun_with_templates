module FunWith
  module Templates
    class FilenameVarData
      attr_accessor :num_format, :var_name, :method_to_call
      
      def initialize( var_name, method_to_call = nil, num_format = nil )
        @num_format = num_format
        @var_name = var_name.to_sym
        @method_to_call = method_to_call.to_sym if method_to_call
      end
      
      alias :name :var_name
      
      def original_string
        "%#{self.num_format}#{self.name}" + (self.method_to_call ? ".#{method_to_call}" : "") + "%"
      end
      
      def fill_in_path( template_path, substitution )
        substitution = self.method_to_call ? substitution.send( self.method_to_call ) : substitution
        substitution = self.num_format ? sprintf("%0#{self.num_format.length}i", substitution ) : substitution
        
        template_path.gsub( original_string, substitution.to_s )
      end
      
      def self.fill_in_path( template_path, var_data, vars )
        var_data.each do |var_dat|
          template_path = var_dat.fill_in_path( template_path, vars[var_dat.name] )
        end
        
        template_path
      end
    end
  end
end