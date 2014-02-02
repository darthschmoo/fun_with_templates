module FunWith
  module Templates
    class UserInputFieldSet
      attr_accessor :fields
  
      def initialize( *args )
        opts = args.last.is_a?(Hash) ? args.pop : {}
    
        index = 0
        @fields = args.map do |sym, label|
          if sym.is_a?(InputField)
            field = sym
            field.index = index
          else
            label = label ? label : sym.to_s.titleize
            field = InputField.new( sym, :label => label, :index => index )
          end
      
          index += 1
          field
        end
      end
  
      def gather( index = nil )
        if index
          @fields[index].gather
        else
          @fields.map(&:gather)
        end
    
        self
      end
  
      def to_display
        @fields.map(&:to_display).join("\n")
      end
  
      def confirm?
        while true
          input = Readline.readline( "Confirm values:\n#{self.to_display}\nPress <ENTER> to confirm, or type in the number of the field to revisit. >>> " ).strip
          index = input.to_i
      
          if input.blank?
            return true
          elsif @fields[index]
            self.gather( index )
          else
            puts "Unsure of input."
          end
        end
      end
  
      def to_hash
        @fields.inject({}){ |memo, field|
          memo[field.sym] = field.value
          memo
        }
      end
    end
  end
end