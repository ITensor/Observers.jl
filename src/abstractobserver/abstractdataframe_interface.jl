# `AbstractObserver` interface requires accessors:
# ```julia
# dataframe(::AbstractObserver)
# set_dataframe(::AbstractObserver, ::AbstractDataFrame)
# ```
Base.parent(observer::AbstractObserver) = dataframe(observer)
Base.copy(observer::AbstractObserver) = set_dataframe(observer, copy(dataframe(observer)))
function Base.getindex(observer::AbstractObserver, rowind, colind)
  return getindex(dataframe(observer), rowind, colind)
end
const SliceIndices = Union{Colon,Regex,AbstractVector,All,Between,Cols,InvertedIndex}
function Base.getindex(observer::AbstractObserver, rowind, colinds::SliceIndices)
  return getindex(dataframe(observer), rowind, colinds)
end
function Base.getindex(observer::AbstractObserver, rowind::Integer, colinds::SliceIndices)
  return getindex(dataframe(observer), rowind, colinds)
end
function Base.getindex(observer::AbstractObserver, rowind::Integer, colinds::Colon)
  return getindex(dataframe(observer), rowind, colinds)
end
function Base.setproperty!(observer::AbstractObserver, f::Symbol, v)
  setproperty!(dataframe(observer), f, v)
  return observer
end
function Base.setindex!(observer::AbstractObserver, v, rowind, colind)
  setindex!(dataframe(observer), v, rowind, colind)
  return observer
end
function Base.append!(observer::AbstractObserver, arg; kwargs...)
  append!(dataframe(observer), arg; kwargs...)
  return observer
end
function Base.prepend!(observer::AbstractObserver, arg; kwargs...)
  prepend!(dataframe(observer), arg; kwargs...)
  return observer
end
function Base.empty!(observer::AbstractObserver)
  empty!(dataframe(observer))
  return observer
end
function Base.push!(observer::AbstractObserver, row; kwargs...)
  push!(dataframe(observer), row; kwargs...)
  return observer
end
function Base.pushfirst!(observer::AbstractObserver, row; kwargs...)
  pushfirst!(dataframe(observer), row; kwargs...)
  return observer
end
function Base.insert!(observer::AbstractObserver, index, row; kwargs...)
  insert!(dataframe(observer), index, row; kwargs...)
  return observer
end

function ConstructionBase.setproperties(observer::AbstractObserver, patch::NamedTuple)
  return typeof(observer)(patch.dataframe)
end

# https://dataframes.juliadata.org/stable/lib/metadata/
DataAPI.nrow(observer::AbstractObserver) = nrow(dataframe(observer))
# metadata, metadatakeys, metadata!, deletemetadata!, emptymetadata!;
function DataAPI.metadata(observer::AbstractObserver, args...; kwargs...)
  return metadata(dataframe(observer), args...; kwargs...)
end
DataAPI.metadatakeys(observer::AbstractObserver) = metadatakeys(dataframe(observer))
function DataAPI.metadata!(observer::AbstractObserver, args...; kwargs...)
  metadata!(dataframe(observer), args...; kwargs...)
  return observer
end
function DataAPI.deletemetadata!(observer::AbstractObserver, args...; kwargs...)
  deletemetadata!(dataframe(observer), args...; kwargs...)
  return observer
end
DataAPI.emptymetadata!(observer::AbstractObserver) = emptymetadata!(dataframe(observer))
# colmetadata, colmetadatakeys, colmetadata!, deletecolmetadata!, emptycolmetadata!.
function DataAPI.colmetadata(observer::AbstractObserver, args...; kwargs...)
  return colmetadata(dataframe(observer), args...; kwargs...)
end
function DataAPI.colmetadatakeys(observer::AbstractObserver, args...)
  return colmetadatakeys(dataframe(observer), args...)
end
function DataAPI.colmetadata!(observer::AbstractObserver, args...; kwargs...)
  colmetadata!(dataframe(observer), args...; kwargs...)
  return observer
end
function DataAPI.deletecolmetadata!(observer::AbstractObserver, args...; kwargs...)
  deletecolmetadata!(dataframe(observer), args...; kwargs...)
  return observer
end
function DataAPI.emptycolmetadata!(observer::AbstractObserver, args...)
  emptycolmetadata!(dataframe(observer), args...)
  return observer
end

DataFrames.index(observer::AbstractObserver) = DataFrames.index(dataframe(observer))
function DataFrames.manipulate(observer::AbstractObserver, args; kwargs...)
  return DataFrames.manipulate(dataframe(observer), args; kwargs...)
end
function DataFrames._try_select_no_copy(observer::AbstractObserver, arg)
  return DataFrames._try_select_no_copy(dataframe(observer), arg)
end
function DataFrames.SubDataFrame(observer::AbstractObserver, args...)
  return SubDataFrame(dataframe(observer), args...)
end
function DataFrames.is_column_insertion_allowed(observer::AbstractObserver)
  return DataFrames.is_column_insertion_allowed(dataframe(observer))
end
# TODO: Add more definitions of `DataFrames.insertcols!`.
function DataFrames.insertcols!(
  observer::AbstractObserver, name_cols::Pair{<:AbstractString}...; kwargs...
)
  insertcols!(dataframe(observer), name_cols...; kwargs...)
  return observer
end
