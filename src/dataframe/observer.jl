using DataFrames: DataFrame

# Convenient constructors of DataFrames with functions as column metadata,
# called an "observer".

const ColumnName = Union{Symbol,String}

function observer(names::Vector{<:ColumnName}, functions::Vector{<:Function}; kwargs...)
  df = DataFrame(map(name -> name => Union{}[], names); kwargs...)
  for (name, func) in zip(names, functions)
    set_function!(df, name, func)
  end
  return df
end

function observer(
  names::Tuple{Vararg{ColumnName}}, functions::Tuple{Vararg{Function}}; kwargs...
)
  return observer(collect(names), collect(functions); kwargs...)
end

# Treat function column data as column metadata.
# Default to empty columns with element type `Union{}`
# so they get automatically promoted to the first type that gets pushed
# into them.
function observer(name_function_pairs::Vector{<:Pair{<:ColumnName,<:Function}}; kwargs...)
  return observer(first.(name_function_pairs), last.(name_function_pairs); kwargs...)
end

function observer(name_function_pairs::Pair{<:ColumnName,<:Function}...; kwargs...)
  return observer(first.(name_function_pairs), last.(name_function_pairs); kwargs...)
end

function observer(name_function_pairs::NamedTuple; kwargs...)
  return observer(keys(name_function_pairs), values(name_function_pairs); kwargs...)
end

function observer(names::Tuple{}, functions::Tuple{}; kwargs...)
  return DataFrame(; kwargs...)
end

observer(; kwargs...) = observer(NamedTuple(kwargs))

function observer(functions::Vector{<:Function}; kwargs...)
  return observer(string.(functions), functions; kwargs...)
end

function observer(::Tuple{}; kwargs...)
  return observer((), (); kwargs...)
end

function observer(functions::Tuple{Vararg{Function}}; kwargs...)
  return observer(string.(functions), functions; kwargs...)
end

function observer(functions::Function...; kwargs...)
  return observer(string.(functions), functions; kwargs...)
end
