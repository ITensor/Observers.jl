# Evaluate the function at the column with name `name`.
# Optiononally ignores any unsupported trailing arguments and
# unssuported keyword arguments that are pass to the function.
function call_function(
  observer::Observer, name, args...; call_function_kwargs=(;), kwargs...
)
  ignore_unsupported_trailing_args = get(
    call_function_kwargs, :ignore_unsupported_trailing_args, false
  )
  ignore_unsupported_kwargs = get(
    call_function_kwargs, :ignore_unsupported_trailing_args, false
  )
  f = get_function(observer, name)
  if ignore_unsupported_trailing_args
    args = remove_unsupported_trailing_args(f, args)
  end
  if ignore_unsupported_kwargs
    kwargs = remove_unsupported_kwargs(f, args, kwargs)
  end
  return f(args...; kwargs...)
end

# Evaluate the function at each column to compute a new row.
# Optionally ignores any unsupported trailing arguments and
# unssuported keyword arguments that are pass to the function.
function call_functions(observer::Observer, args...; call_function_kwargs=(;), kwargs...)
  return Dict(
    map(names(observer)) do name
      return name =>
        call_function(observer, name, args...; call_function_kwargs, kwargs...)
    end,
  )
end

"""
    update!(obs::Observer, args...; promote=true, kwargs...)

Update the observer by executing the functions in it.

Promotes the column data if needed by default. That can be disabled
by setting `promote=false`.
"""
function update!(
  observer::Observer,
  args...;
  call_function_kwargs=(;
    ignore_unsupported_trailing_args=true, ignore_unsupported_kwargs=true
  ),
  push!_kwargs=(; promote=true),
  kwargs...,
)
  # TODO: Narrow the element type of empty Observers based on the first input.
  function_outputs = call_functions(observer, args...; call_function_kwargs, kwargs...)
  push!(observer, function_outputs; push!_kwargs...)
  return observer
end
