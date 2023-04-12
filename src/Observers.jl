module Observers

export Observer, update!, get_function, set_function!, insert_function!
# Deprecated
export results

using Accessors
using Compat
using ConstructionBase
using DataFrames
using DataAPI

include("method_utils.jl")
include("observer.jl")
include("dataframes_interface.jl")
include("update.jl")
include("deprecated.jl")

end # module
