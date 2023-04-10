Base.parent(observer::Observer) = data(observer)
Base.copy(observer::Observer) = set_data(observer, copy(data(observer)))
Base.getindex(observer::Observer, rowind, colind) = getindex(data(observer), rowind, colind)
const SliceIndices = Union{Colon,Regex,AbstractVector,All,Between,Cols,InvertedIndex}
function Base.getindex(observer::Observer, rowind, colinds::SliceIndices)
  return getindex(data(observer), rowind, colinds)
end
function Base.getindex(observer::Observer, rowind::Integer, colinds::SliceIndices)
  return getindex(data(observer), rowind, colinds)
end
function Base.getindex(observer::Observer, rowind::Integer, colinds::Colon)
  return getindex(data(observer), rowind, colinds)
end
Base.setproperty!(observer::Observer, f::Symbol, v) = setproperty!(data(observer), f, v)
function Base.setindex!(observer::Observer, v, rowind, colind)
  return setindex!(data(observer), v, rowind, colind)
end
Base.append!(observer::Observer, arg; kwargs...) = append!(data(observer), arg; kwargs...)
Base.prepend!(observer::Observer, arg; kwargs...) = prepend!(data(observer), arg; kwargs...)
Base.empty!(observer::Observer) = set_data(observer, empty!(data(observer)))
Base.push!(observer::Observer, row; kwargs...) = push!(data(observer), row; kwargs...)
function Base.pushfirst!(observer::Observer, row; kwargs...)
  return pushfirst!(data(observer), row; kwargs...)
end
function Base.insert!(observer::Observer, index, row; kwargs...)
  return insert!(data(observer), index, row; kwargs...)
end

ConstructionBase.setproperties(observer::Observer, patch::NamedTuple) = Observer(patch.data)

# https://dataframes.juliadata.org/stable/lib/metadata/
DataAPI.nrow(observer::Observer) = nrow(data(observer))
# metadata, metadatakeys, metadata!, deletemetadata!, emptymetadata!;
function DataAPI.metadata(observer::Observer, args...; kwargs...)
  return metadata(data(observer), args...; kwargs...)
end
DataAPI.metadatakeys(observer::Observer) = metadatakeys(data(observer))
function DataAPI.metadata!(observer::Observer, args...; kwargs...)
  return metadata!(data(observer), args...; kwargs...)
end
function DataAPI.deletemetadata!(observer::Observer, args...; kwargs...)
  return deletemetadata!(data(observer), args...; kwargs...)
end
DataAPI.emptymetadata!(observer::Observer) = emptymetadata!(data(observer))
# colmetadata, colmetadatakeys, colmetadata!, deletecolmetadata!, emptycolmetadata!.
function DataAPI.colmetadata(observer::Observer, args...; kwargs...)
  return colmetadata(data(observer), args...; kwargs...)
end
function DataAPI.colmetadatakeys(observer::Observer, args...)
  return colmetadatakeys(data(observer), args...)
end
function DataAPI.colmetadata!(observer::Observer, args...; kwargs...)
  return colmetadata!(data(observer), args...; kwargs...)
end
function DataAPI.deletecolmetadata!(observer::Observer, args...; kwargs...)
  return deletecolmetadata!(data(observer), args...; kwargs...)
end
function DataAPI.emptycolmetadata!(observer::Observer, args...)
  return emptycolmetadata!(data(observer), args...)
end

DataFrames.index(observer::Observer) = DataFrames.index(data(observer))
function DataFrames.manipulate(observer::Observer, args; kwargs...)
  return DataFrames.manipulate(data(observer), args; kwargs...)
end
function DataFrames._try_select_no_copy(observer::Observer, arg)
  return DataFrames._try_select_no_copy(data(observer), arg)
end
DataFrames.SubDataFrame(observer::Observer, args...) = SubDataFrame(data(observer), args...)
