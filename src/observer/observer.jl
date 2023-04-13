struct Observer{DF<:AbstractDataFrame} <: AbstractObserver
  dataframe::DF
end
# Field accessors (getters and setters)
# Required interface for `AbstractObserver`.
dataframe(observer::Observer) = getfield(observer, :dataframe)
set_dataframe(observer::Observer, dataframe) = (@set observer.dataframe = dataframe)

# Constructors
Observer(args...; kwargs...) = Observer(observer_dataframe(args...; kwargs...))
