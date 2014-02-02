module FunWith
  module Templates
    # Asks you some questions, and gets some answers.
    class Inquisitor
      # takes a series of one_or_two-item arrays.  First item in each is the symbol, the second is an optional label 
      def gather_fields( *fields )
        fieldset = UserInputFieldSet.new( *fields )

        puts "Gathering fields.  If you make a mistake you may fix it at the end:"

        fieldset.gather

        fieldset.confirm? ? fieldset.to_hash : nil
      end
    end
  end
end

