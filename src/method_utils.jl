# Remove any trailing arguments that would not be accepted
# by any method definitions.
function remove_unsupported_trailing_args(f::Function, args::Tuple)
  if !hasmethod(f, typeof.(args))
    return remove_unsupported_trailing_args(f, Base.front(args))
  end
  return args
end

# Remove any of the input keyword arguments that are not declared as part
# of the method definition corresponding to the input arguments.
function remove_unsupported_kwargs(f::Function, args::Tuple, kwargs)
  return remove_unsupported_kwargs(which(f, typeof.(args)), kwargs)
end

# Remove any of the input keyword arguments that are not declared as part
# of the specified method definition.
function remove_unsupported_kwargs(method::Method, kwargs)
  # Extract the keywords of the keyword arguments declared in the definition of method
  method_keywords = Base.kwarg_decl(method)
  # Remove any keyword argument varargs in the method definition.
  filter!(
    x -> !(length(string(x)) ≥ 4 && string(x)[(end - 2):end] == "..."), method_keywords
  )
  # Attach the arguments of the input keyword arguments for the keywords
  # defined with the method.
  return method_keywords .=> [kwargs[keyword] for keyword in method_keywords]
end
