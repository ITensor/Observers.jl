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
