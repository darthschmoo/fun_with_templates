require 'fun_with_files'
require 'fun_with_version_strings'
require 'erb'
require 'debugger'

module FunWith
  module Templates
  end
end


FunWith::Files::RootPath.rootify( FunWith::Templates, __FILE__.fwf_filepath.dirname.up )
FunWith::VersionStrings.versionize( FunWith::Templates )

# FunWith::Templates.root( "lib", "core_extensions" ).requir
# FunWith::Templates.root( "lib", "templates" ).requir
FunWith::Templates.root( "lib" ).requir