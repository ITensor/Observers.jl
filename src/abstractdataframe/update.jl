# Evaluate the function at the column with name `name`.
# Optiononally ignores any unsupported trailing arguments and
# unssuported keyword arguments that are pass to the function.
function call_function(
  df::AbstractDataFrame, name, args...; call_function_kwargs=(;), kwargs...
)
  call_function_kwargs = (;
    default_call_function_kwargs(call_function)..., call_function_kwargs...
  )
  @compat (; ignore_unsupported_trailing_args, ignore_unsupported_kwargs) =
    call_function_kwargs
  f = get_function(df, name)
  if ignore_unsupported_trailing_args
    args = remove_unsupported_trailing_args(f, args)
  end
  if ignore_unsupported_kwargs
    kwargs = remove_unsupported_kwargs(f, args, kwargs)
  end
  return f(args...; kwargs...)
end

function default_call_function_kwargs(::typeof(call_function))
  return (; ignore_unsupported_trailing_args=false, ignore_unsupported_kwargs=false)
end

# Evaluate the function at each column to compute a new row.
# Optionally ignores any unsupported trailing arguments and
# unssuported keyword arguments that are pass to the function.
function call_functions(df::AbstractDataFrame, args...; call_function_kwargs=(;), kwargs...)
  return Dict(
    map(names(df)) do name
      return name =>
        call_function(df, name, args...; call_function_kwargs, kwargs...)
    end,
  )
end

"""
    update!(
      df::AbstractDataFrame,
      args...;
      push!_kwargs=(; promote=true, skip_all_missing=true, skip_all_nothing=true),
      kwargs...,
    )

Update the data frame `df` by executing the functions stored on each column,
passing the arguments `args...` and keyword arguments `kwargs...`
to each function.

By default, `update!` promotes the type of the column data if needed,
if new data can't be converted to the current data type of the column.
That can be disabled by setting `push!_kwargs=(; promote=false)`.

Also, by default, rows that have all `missing` data or all `nothing`
data don't get pushed into the `df`. That can be disabled by setting
`push!_kwargs=(; skip_all_missing=false)` and/or `push!_kwargs=(; skip_all_nothing=false)`.
"""
function update!(
  df::AbstractDataFrame, args...; push!_kwargs=(;), call_function_kwargs=(;), kwargs...
)
  # TODO: Replace with `update!_kwargs`!
  push!_kwargs = (; default_push!_kwargs(update!)..., push!_kwargs...)
  skip_all_missing = push!_kwargs.skip_all_missing
  skip_all_nothing = push!_kwargs.skip_all_nothing
  push!_kwargs = Base.structdiff(push!_kwargs, (; skip_all_missing, skip_all_nothing))
  call_function_kwargs = (;
    default_call_function_kwargs(update!)..., call_function_kwargs...
  )
  function_outputs = call_functions(df, args...; call_function_kwargs, kwargs...)
  if skip_all_missing && all(ismissing, values(function_outputs))
    return df
  end
  if skip_all_nothing && all(isnothing, values(function_outputs))
    return df
  end
  push!(df, function_outputs; push!_kwargs...)
  return df
end

function default_push!_kwargs(::typeof(update!))
  return (; promote=true, skip_all_missing=true, skip_all_nothing=true)
end

function default_call_function_kwargs(::typeof(update!))
  return (; ignore_unsupported_trailing_args=true, ignore_unsupported_kwargs=true)
end
