module Observers

export Observer, update!, get_function, set_function!, insert_function!
# Deprecated
export results

using Accessors
using Compat
using ConstructionBase
using DataFrames
using DataAPI

include("base/method_utils.jl")
include("abstractdataframe/column_functions.jl")
include("abstractdataframe/update.jl")
include("dataframe/observer_dataframe.jl")
include("abstractobserver/abstractobserver.jl")
include("abstractobserver/abstractdataframe_interface.jl")
include("abstractobserver/deprecated.jl")
include("observer/observer.jl")

end # module
