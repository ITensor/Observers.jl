# Evaluate the function at the column with name `name`.
# Optiononally ignores any unsupported trailing arguments and
# unssuported keyword arguments that are pass to the function.
function call_function(
  df::AbstractDataFrame, name, args...; call_function_kwargs=(;), kwargs...
)
  @compat (; ignore_unsupported_trailing_args, ignore_unsupported_kwargs) = (;
    ignore_unsupported_trailing_args=false,
    ignore_unsupported_kwargs=false,
    call_function_kwargs...,
  )
  f = get_function(df, name)
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
function call_functions(df::AbstractDataFrame, args...; call_function_kwargs=(;), kwargs...)
  return Dict(
    map(names(df)) do name
      return name => call_function(df, name, args...; call_function_kwargs, kwargs...)
    end,
  )
end

"""
    update!(
      df::AbstractDataFrame,
      args...;
      update!_kwargs=(; promote=true, skip_all_missing=true, skip_all_nothing=true),
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
`update!_kwargs=(; skip_all_missing=false)` and/or `update!_kwargs=(; skip_all_nothing=false)`.
"""
function update!(df::AbstractDataFrame, args...; update!_kwargs=(;), kwargs...)
  @compat (; promote, skip_all_missing, skip_all_nothing, ignore_unsupported_trailing_args, ignore_unsupported_kwargs) = (;
    promote=true,
    skip_all_missing=true,
    skip_all_nothing=true,
    ignore_unsupported_trailing_args=true,
    ignore_unsupported_kwargs=true,
    update!_kwargs...,
  )
  call_function_kwargs = (; ignore_unsupported_trailing_args, ignore_unsupported_kwargs)
  function_outputs = call_functions(df, args...; call_function_kwargs, kwargs...)
  if skip_all_missing && all(ismissing, values(function_outputs))
    return df
  end
  if skip_all_nothing && all(isnothing, values(function_outputs))
    return df
  end
  push!(df, function_outputs; promote)
  return df
end
