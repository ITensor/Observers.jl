module Observers

export Observer, update!

using Accessors
using ConstructionBase
using DataFrames
using DataAPI

include("method_utils.jl")
include("observer.jl")
include("dataframes_interface.jl")
include("update.jl")

end # module
