module Observers

export observer, update!, get_function, set_function!, insert_function!
# Deprecated
export results

## using Accessors
## using Compat
## using ConstructionBase
## using DataFrames
## using DataAPI

include("base/method_utils.jl")
include("abstractdataframe/column_functions.jl")
include("abstractdataframe/deprecated.jl")
include("dataframe/observer.jl")
include("dataframe/deprecated.jl")

end # module
