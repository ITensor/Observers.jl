module Observers
export observer, update!, get_function, set_function!, insert_function!
# Deprecated
export results
include("base/method_utils.jl")
include("abstractdataframe/column_functions.jl")
include("abstractdataframe/deprecated.jl")
include("dataframe/observer.jl")
include("dataframe/deprecated.jl")
end
