module Observers
export observer, update!, get_function, set_function!, insert_function!
# Deprecated
export results
include("method_utils.jl")
include("column_functions.jl")
include("observer.jl")
include("deprecated.jl")
# For backwards compatibility since some
# libraries were using `Observers.DataFrames`.
using DataFrames: DataFrames
end
