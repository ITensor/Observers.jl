# Evaluate the function at the column with name `name`.
function call_function(observer::Observer, name, args...; ignore_unused_kwargs=true, kwargs...)
  f = get_function(observer, name)
  args = remove_undef_trailing_args(f, args...; kwargs...)
  if ignore_unused_kwargs
    kwargs = remove_undef_kwargs(f, args...; kwargs...)
  end
  return f(args...; kwargs...)
end

# Evaluate the function at each column to compute a new row.
function call_functions(observer::Observer, args...; kwargs...)
  return Dict([name => call_function(observer, name, args...; kwargs...) for name in names(observer)])
end

"""
    update!(obs::Observer, args...; promote=true, kwargs...)

Update the observer by executing the functions in it.

Promotes the column data if needed by default. That can be disabled
by setting `promote=false`.
"""
function update!(observer::Observer, args...; promote=true, call_functions_kwargs...)
  # TODO: Narrow the element type of empty Observers based on the first input.
  push!(observer, call_functions(observer, args...; call_functions_kwargs...); promote)
  return observer
end
