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
Observer() = Observer(DataFrame())

function Observer(name_function_pairs::Vector{<:Pair})
  name_function_dict = Dict(name_function_pairs)
  observer = Observer(DataFrame([name => [] for name in keys(name_function_dict)]))
  for name in keys(name_function_dict)
    set_function!(observer, name, name_function_dict[name])
  end
  return observer
end

function Observer(key_function_pairs::Pair...)
  return Observer([key_function_pairs...])
end

function Observer(functions::Vector{<:Function})
  return Observer(string.(functions) .=> functions)
end

function Observer(functions::Function...)
  return Observer([(string.(functions) .=> functions)...])
end
