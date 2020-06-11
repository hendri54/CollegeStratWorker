module CollegeStratWorker

using DocStringExtensions
using CommonLH, ModelParams, StructLH, UtilityFunctionsLH

# const Double = Float64;
const TimeInt = UInt8;

export Worker, WorkerSet, WorkerSetSwitches, WorkerUtility
# Utility
export cons_age1, mu_wealth, 
    lifetime_utility, lifetime_utility_grid, lifetime_utility_vector
# Worker
export log_exper_profile, exper_profile, lifetime_earnings, 
    validate_worker

# WorkerSet
export make_worker_set, make_worker,
    u_fixed, wage, wage_by_school
# WorkHistories
export WorkHistories, simulate_workers!, validate_wh, 
    h_work_start, k_work_start, school_index, work_start_ages

include("worker_types.jl")
include("utility.jl")
include("worker.jl")
include("worker_set.jl")
include("simulate.jl")

end # module
