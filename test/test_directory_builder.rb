# require 'helper'

# pulling this feature.  May not be worth implementing.
# class TestDirectoryBuilder < FunWith::Templates::TestCase
#   context "testing template() function which FWT adds to FunWith::Files::DirectoryBuilder" do
#     setup do
#       @templates_dir = FunWith::Templates.root("test", "templates")
#     end
# 
#     should "successfully print off a template" do
#       FunWith::Files::DirectoryBuilder.tmpdir do |b|
#         b.template( @templates_dir.join("00", "a.rb.template") ) do |coll|
#           coll.var(:module, "Cats")
#           coll.var(:class, "Kitten")
#           coll.var(:args, %w(lick paws?))
#         end
#         
#         
#         
#         raise "WORK ON THIS!!!!"
#       end
#     end
#   end
# end
