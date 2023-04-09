module Observers

# TODO: Deprecate `results`, `empty_results!`, `empty_results`.
# export Observer, results, empty_results!, empty_results, update!
export Observer, update!

# TODO: Delete.
# const FunctionAndResults = NamedTuple{(:f,:results),Tuple{Union{Nothing,Function},Any}}

# TODO: Delete.
# struct Observer <: AbstractDict{String,FunctionAndResults}
#   data::Dict{String,FunctionAndResults}
# end

using Accessors
using ConstructionBase
using DataFrames
using DataAPI

struct Observer{DF<:AbstractDataFrame} <: AbstractDataFrame
  data::DF
end
set_data(observer::Observer, data) = (@set observer.data = data)
data(observer::Observer) = getfield(observer, :data)

Base.parent(observer::Observer) = data(observer)
Base.copy(observer::Observer) = set_data(observer, copy(data(observer)))
Base.getindex(observer::Observer, rowind, colind) = getindex(data(observer), rowind, colind)
const SliceIndices = Union{Colon,Regex,AbstractVector,All,Between,Cols,InvertedIndex}
Base.getindex(observer::Observer, rowind, colinds::SliceIndices) = getindex(data(observer), rowind, colinds)
Base.getindex(observer::Observer, rowind::Integer, colinds::SliceIndices) = getindex(data(observer), rowind, colinds)
Base.getindex(observer::Observer, rowind::Integer, colinds::Colon) = getindex(data(observer), rowind, colinds)
Base.setproperty!(observer::Observer, f::Symbol, v) = setproperty!(data(observer), f, v)
Base.setindex!(observer::Observer, v, rowind, colind) = setindex!(data(observer), v, rowind, colind)
Base.append!(observer::Observer, arg; kwargs...) = append!(data(observer), arg; kwargs...)
Base.prepend!(observer::Observer, arg; kwargs...) = prepend!(data(observer), arg; kwargs...)
Base.empty!(observer::Observer) = set_data(observer, empty!(data(observer)))
Base.push!(observer::Observer, row; kwargs...) = push!(data(observer), row; kwargs...)
Base.pushfirst!(observer::Observer, row; kwargs...) = pushfirst!(data(observer), row; kwargs...)
Base.insert!(observer::Observer, index, row; kwargs...) = insert!(data(observer), index, row; kwargs...)

ConstructionBase.setproperties(observer::Observer, patch::NamedTuple) = Observer(patch.data)

# https://dataframes.juliadata.org/stable/lib/metadata/
DataAPI.nrow(observer::Observer) = nrow(data(observer))
# metadata, metadatakeys, metadata!, deletemetadata!, emptymetadata!;
DataAPI.metadata(observer::Observer, args...; kwargs...) = metadata(data(observer), args...; kwargs...)
DataAPI.metadatakeys(observer::Observer) = metadatakeys(data(observer))
DataAPI.metadata!(observer::Observer, args...; kwargs...) = metadata!(data(observer), args...; kwargs...)
DataAPI.deletemetadata!(observer::Observer, args...; kwargs...) = deletemetadata!(data(observer), args...; kwargs...)
DataAPI.emptymetadata!(observer::Observer) = emptymetadata!(data(observer))
# colmetadata, colmetadatakeys, colmetadata!, deletecolmetadata!, emptycolmetadata!.
DataAPI.colmetadata(observer::Observer, args...; kwargs...) = colmetadata(data(observer), args...; kwargs...)
DataAPI.colmetadatakeys(observer::Observer, args...) = colmetadatakeys(data(observer), args...)
DataAPI.colmetadata!(observer::Observer, args...; kwargs...) = colmetadata!(data(observer), args...; kwargs...)
DataAPI.deletecolmetadata!(observer::Observer, args...; kwargs...) = deletecolmetadata!(data(observer), args...; kwargs...)
DataAPI.emptycolmetadata!(observer::Observer, args...) = emptycolmetadata!(data(observer), args...)

DataFrames.index(observer::Observer) = DataFrames.index(data(observer))
DataFrames.manipulate(observer::Observer, args; kwargs...) = DataFrames.manipulate(data(observer), args; kwargs...)
DataFrames._try_select_no_copy(observer::Observer, arg) = DataFrames._try_select_no_copy(data(observer), arg)
DataFrames.SubDataFrame(observer::Observer, args...) = SubDataFrame(data(observer), args...)

Observer() = Observer(DataFrame())

get_function(observer::Observer, name) = colmetadata(observer, name, "function")
# Default to `style=:note`, so the metadata gets preserved through
# verious `DataFrame` operations.
function set_function!(observer::Observer, name, f; style=:note)
  if name ∉ names(observer)
    observer[!, name] = []
  end
  colmetadata!(observer, name, "function", f; style)
  return observer
end

function Observer(name_function_pairs::Vector{<:Pair})
  name_function_dict = Dict(name_function_pairs)
  observer = Observer(DataFrame([name => [] for name in keys(name_function_dict)]))
  for name in keys(name_function_dict)
    set_function!(observer, name, name_function_dict[name])
  end
  return observer
end

function Observer(functions::Vector{<:Function})
  return Observer(string.(functions) .=> functions)
end

function Observer(key_function_pairs::Pair...)
  return Observer([key_function_pairs...])
end

function Observer(functions::Function...)
  return Observer([functions...])
end

# TODO: Rewrite as a function `remove_unused_kwargs` that doesn't execute the function.
function call_and_ignore_unused_kwargs(f::Function, args...; kwargs...)
  # collect the types of each positional argument being passed into the observer
  args_types = typeof.(args)
  # loop over the sequences of possible positional arguments
  for i in 0:length(args_types)
    tlist = args_types[1:i]
    # if a function with argument matching tlist exists:
    if hasmethod(f, tlist)
      # check the kwargs of the method
      kwargs_list = Base.kwarg_decl(which(f, tlist))
      # remove the input kwargs from the kwargs of the existing method
      filter!(x -> !(length(string(x)) ≥ 4 && string(x)[end-2:end] == "..."), kwargs_list)
      # execute the function
      return f(args[1:i]...; (kwargs_list .=> [kwargs[κ] for κ in kwargs_list])...)
    end
  end
  return error("No method found")
end

# Evaluate the function at the column with name `name`
function call_function(observer::Observer, name, args...; ignore_unused_kwargs=true, kwargs...)
  f = get_function(observer, name)
  if ignore_unused_kwargs
    return call_and_ignore_unused_kwargs(f, args...; kwargs...)
  end
  return f(args...; kwargs...)
end

# Evaluate the function at each column to compute a new row
function call_functions(observer::Observer, args...; kwargs...)
  return Dict([name => call_function(observer, name, args...; kwargs...) for name in names(observer)])
end

"""
    update!(obs::Observer, args...; kwargs...)

Update the observer by executing the functions in it.
"""
function update!(observer::Observer, args...; kwargs...)
  # TODO: Narrow or expand the element type of each column as needed.
  push!(observer, call_functions(observer, args...; kwargs...))
  return observer
end

end # module
