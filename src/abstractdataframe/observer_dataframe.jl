# Function accessors interface
get_function(df::AbstractDataFrame, name) = colmetadata(df, name, "function")

# Set the function of a column of the Observer.
# Default to `style=:note`, so the metadata gets preserved through
# verious `DataFrame` operations.
function set_function!(df::AbstractDataFrame, name, f::Function; style=:note)
  colmetadata!(df, name, "function", f; style)
  return df
end

function set_function!(df::AbstractDataFrame, name_function::Pair{<:Any,<:Function}; kwargs...)
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
  # Append a new column and then set the function.
  df[!, name] = isempty(df) ? Union{}[] : fill(missing, nrow(df))
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
