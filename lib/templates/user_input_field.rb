module FunWith
  module Templates
    class UserInputField
      attr_accessor :sym, :label, :value, :index
  
      # :name is mandatory
      def initialize( sym, opts = {} )
        @sym   = sym
        @label = opts[:label] || sym.to_s.capitalize
        @index = opts[:index]
      end
  
      def gather
        @value = Readline.readline( "#{self.to_display_key} : "  ).strip
      end
  
      def to_display_key
        "[#{@index}]\t#{@label}"
      end
  
      def to_display
        "#{self.to_display_key} : #{@value}"
      end
    end
  end
end
