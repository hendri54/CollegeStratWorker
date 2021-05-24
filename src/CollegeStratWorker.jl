module CollegeStratWorker

using DocStringExtensions, Interpolations, Random
using CollegeStratBase
using CommonLH, StructLH, UtilityFunctionsLH, ModelObjectsLH, ModelParams

import Roots: find_zero

# const Double = Float64;
const TimeInt = UInt8;

export Worker, WorkerUtility
# Utility
export cons_age1, mu_wealth, 
    lifetime_utility, lifetime_utility_grid, lifetime_utility_vector,
    lifetime_utility_function, interpolation_deviation,
    lifetime_utility_function_grid
# Worker
export log_exper_profile, exper_profile, earn_profile, lifetime_earnings, 
    ltincome_from_utility,
    make_test_worker, validate_worker

# WorkHistories
export WorkHistories, make_test_work_histories,
    simulate_workers!, simulate_one_worker!, validate_wh, 
    h_work_start, k_work_start, school_index, work_start_ages

include("worker_types.jl")
include("utility.jl")
include("worker.jl")
include("lifetime_utility.jl")
include("compensating_variations.jl")
# include("worker_set.jl")
include("simulate.jl")

end # module
