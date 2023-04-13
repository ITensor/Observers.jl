# `AbstractObserver` interface requires accessors:
# ```julia
# dataframe(::AbstractObserver)
# set_dataframe(::AbstractObserver, ::AbstractDataFrame)
# ```
Base.parent(observer::AbstractObserver) = dataframe(observer)
Base.copy(observer::AbstractObserver) = set_dataframe(observer, copy(dataframe(observer)))
Base.getindex(observer::AbstractObserver, rowind, colind) = getindex(dataframe(observer), rowind, colind)
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
Base.setproperty!(observer::AbstractObserver, f::Symbol, v) = setproperty!(dataframe(observer), f, v)
function Base.setindex!(observer::AbstractObserver, v, rowind, colind)
  return setindex!(dataframe(observer), v, rowind, colind)
end
Base.append!(observer::AbstractObserver, arg; kwargs...) = append!(dataframe(observer), arg; kwargs...)
Base.prepend!(observer::AbstractObserver, arg; kwargs...) = prepend!(dataframe(observer), arg; kwargs...)
Base.empty!(observer::AbstractObserver) = set_dataframe(observer, empty!(dataframe(observer)))
Base.push!(observer::AbstractObserver, row; kwargs...) = push!(dataframe(observer), row; kwargs...)
function Base.pushfirst!(observer::AbstractObserver, row; kwargs...)
  return pushfirst!(dataframe(observer), row; kwargs...)
end
function Base.insert!(observer::AbstractObserver, index, row; kwargs...)
  return insert!(dataframe(observer), index, row; kwargs...)
end

ConstructionBase.setproperties(observer::AbstractObserver, patch::NamedTuple) = typeof(observer)(patch.dataframe)

# https://dataframes.juliadata.org/stable/lib/metadata/
DataAPI.nrow(observer::AbstractObserver) = nrow(dataframe(observer))
# metadata, metadatakeys, metadata!, deletemetadata!, emptymetadata!;
function DataAPI.metadata(observer::AbstractObserver, args...; kwargs...)
  return metadata(dataframe(observer), args...; kwargs...)
end
DataAPI.metadatakeys(observer::AbstractObserver) = metadatakeys(dataframe(observer))
function DataAPI.metadata!(observer::AbstractObserver, args...; kwargs...)
  return metadata!(dataframe(observer), args...; kwargs...)
end
function DataAPI.deletemetadata!(observer::AbstractObserver, args...; kwargs...)
  return deletemetadata!(dataframe(observer), args...; kwargs...)
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
  return colmetadata!(dataframe(observer), args...; kwargs...)
end
function DataAPI.deletecolmetadata!(observer::AbstractObserver, args...; kwargs...)
  return deletecolmetadata!(dataframe(observer), args...; kwargs...)
end
function DataAPI.emptycolmetadata!(observer::AbstractObserver, args...)
  return emptycolmetadata!(dataframe(observer), args...)
end

DataFrames.index(observer::AbstractObserver) = DataFrames.index(dataframe(observer))
function DataFrames.manipulate(observer::AbstractObserver, args; kwargs...)
  return DataFrames.manipulate(dataframe(observer), args; kwargs...)
end
function DataFrames._try_select_no_copy(observer::AbstractObserver, arg)
  return DataFrames._try_select_no_copy(dataframe(observer), arg)
end
DataFrames.SubDataFrame(observer::AbstractObserver, args...) = SubDataFrame(dataframe(observer), args...)
