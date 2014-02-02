module Kernel
  def template_evaluator_set_local_vars( locals = {}, &block )
    old_local_vars = {}

    for k, v in locals
      var = :"@#{k}"
      old_local_vars[k] = instance_variable_get( var )
      instance_variable_set( var, v )
    end

    yield
  ensure      # make all as it once was
    for k, v in old_local_vars
      var = :"@#{k}"
      instance_variable_set( var, v )
    end
  end
end
