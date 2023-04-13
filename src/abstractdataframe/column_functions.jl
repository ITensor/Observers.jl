# Function accessors interface
get_function(df::AbstractDataFrame, name) = colmetadata(df, name, "function")

# Set the function of a column of the Observer.
# Default to `style=:note`, so the metadata gets preserved through
# verious `DataFrame` operations.
function set_function!(df::AbstractDataFrame, name, f::Function; style=:note)
  colmetadata!(df, name, "function", f; style)
  return df
end

function set_function!(
  df::AbstractDataFrame, name_function::Pair{<:Any,<:Function}; kwargs...
)
  return set_function!(df, first(name_function), last(name_function); kwargs...)
end

function set_function!(df::AbstractDataFrame, f::Function; kwargs...)
  return set_function!(df, string(f), f; kwargs...)
end

# Insert a new function into the Observer by appending a new column
# filled with `missing`.
# Errors if the column already exists.
function insert_function!(df::AbstractDataFrame, name, f::Function; set_function!_kwargs...)
  if name ∈ names(df)
    error(
      "Trying to insert a new function with `insert_function!`, but a column with name `$(name)` already exists. Use `set_function!` if you want to replace the function of an existing column, or use a different name than the existing column names `$(names(df))`.",
    )
  end
  # Append a new column and then set the function of that column.
  insertcols!(df, name => isempty(df) ? Union{}[] : missing)
  set_function!(df, name, f; set_function!_kwargs...)
  return df
end

function insert_function!(
  df::AbstractDataFrame, name_function::Pair{<:Any,<:Function}; kwargs...
)
  return insert_function!(df, first(name_function), last(name_function); kwargs...)
end

function insert_function!(df::AbstractDataFrame, f::Function; kwargs...)
  return insert_function!(df, string(f), f; kwargs...)
end

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
