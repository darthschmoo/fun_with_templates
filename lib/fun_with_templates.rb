require 'fun_with_gems'
require 'fun_with_string_colors'
require 'erb'
require 'debugger'


FunWith::Gems.make_gem_fun( "FunWith::Templates" )
FunWith::StringColors.activate
String.colorize( true )

# module FunWith
#   module Templates
#   end
# end
# 
# 
# FunWith::Files::RootPath.rootify( FunWith::Templates, __FILE__.fwf_filepath.dirname.up )
# FunWith::VersionStrings.versionize( FunWith::Templates )
# 
# # FunWith::Templates.root( "lib", "core_extensions" ).requir
# # FunWith::Templates.root( "lib", "templates" ).requir
# FunWith::Templates.root( "lib" ).requir