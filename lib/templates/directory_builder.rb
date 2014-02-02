# Add-on to FunWith::Files
module FunWith
  module Files
    class DirectoryBuilder
      def self.template( src, dest, vars = {} )
        if src.directory?
          TemplateEvaluator.eval_dir( src, dest, vars )
        elsif src.file?
          TemplateEvaluator.result_to_file( src, dest, vars )
        end
      end
    end
  end
end
