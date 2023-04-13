abstract type AbstractObserver <: AbstractDataFrame end
# `AbstractObserver` interface required accessors:
dataframe(::AbstractObserver) = error("Not implemented")
set_dataframe(::AbstractObserver, x) = error("Not implemented")
