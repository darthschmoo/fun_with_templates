# Add-on to FunWith::Files  # Not going to implement just now.  Having trouble deciding what it ought to do.
# module FunWith
#   module Files
#     class DirectoryBuilder
#       def template( *args, &block )
#         vars = args.last.is_a?(Hash) ? args.pop : {}
#         
#         if args.length == 2
#           src = args.first
#           dst = args.last
#         elsif args.length == 1
#           src = args.first
#           dst = self.current_path
#         else
#           raise ArgumentError.new( "Wrong number of arguments:  template(src, dst, variables)" )
#         end
#         
#         if block_given?
#           collector = FunWith::Templates::VarCollector.collect do |c|
#             yield c
#           end
#           
#           vars.merge!( collector )
#         end
#         
#         FunWith::Templates::TemplateEvaluator.result_to_file( src, dst, vars )
#         
#         # if src.directory?
#         #   FunWith::Templates::TemplateEvaluator.evaluate( src, dest, vars )
#         # elsif src.file?
#         #   FunWith::Templates::TemplateEvaluator.result_to_file( src, dest, vars )
#         # end
#       end
#     end
#   end
# end
