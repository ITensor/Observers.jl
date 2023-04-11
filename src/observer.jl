struct Observer{DF<:AbstractDataFrame} <: AbstractDataFrame
  data::DF
end
# Field accessors (getters and setters)
data(observer::Observer) = getfield(observer, :data)
set_data(observer::Observer, data) = (@set observer.data = data)

# Function accessors interface
get_function(observer::Observer, name) = colmetadata(observer, name, "function")

# Set the function of a column of the Observer.
# Default to `style=:note`, so the metadata gets preserved through
# verious `DataFrame` operations.
function set_function!(observer::Observer, name, f; style=:note)
  colmetadata!(observer, name, "function", f; style)
  return observer
end

# Insert a new function into the Observer by appending a new column
# filled with `missing`.
# Errors if the column already exists.
function insert_function!(observer::Observer, name, f; set_function!_kwargs...)
  if name ∈ names(observer)
    error("Trying to insert a new function, but column with name $(name) already exists.")
  end
  # Append a new column and then set the function.
  observer[!, name] = fill(missing, nrow(observer))
  set_function!(observer, name, f; set_function!_kwargs...)
  return observer
end

# Constructors

# In general, fall back to `DataFrame` constructors.
Observer(x; kwargs...) = Observer(DataFrame(x; kwargs...))

Observer(; kwargs...) = Observer(DataFrame(; kwargs...))

# Treat function column data as column metadata.
# Default to empty columns with element type `Union{}`
# so they get automatically promoted to the first type that gets pushed
# into them.
function Observer(
  name_function_pairs::Vector{<:Pair{T,<:Function}}; kwargs...
) where {T<:Union{Symbol,String}}
  observer = Observer(
    [first(name_function) => Union{}[] for name_function in name_function_pairs]; kwargs...
  )
  name_function_dict = Dict(name_function_pairs)
  for name in keys(name_function_dict)
    set_function!(observer, name, name_function_dict[name])
  end
  return observer
end

function Observer(
  key_function_pairs::Pair{T,<:Function}...; kwargs...
) where {T<:Union{Symbol,String}}
  return Observer(Pair{T,Function}[key_function_pairs...]; kwargs...)
end

function Observer(functions::Vector{<:Function}; kwargs...)
  return Observer(
    Pair{String,Function}[string(func) => func for func in functions]; kwargs...
  )
end

function Observer(functions::Function...; kwargs...)
  return Observer(
    Pair{String,Function}[string(func) => func for func in functions]; kwargs...
  )
end
