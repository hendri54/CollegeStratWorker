"""
    $(SIGNATURES)

Worker utility function u(c).
Not a `ModelObject`. Constructed from [`WorkerSet`](@ref).
"""
mutable struct WorkerUtility{F1 <: AbstractFloat}
    util :: UtilityFunctionsLH.UtilityOneArg
    discFactor :: F1
    "Fixed utility from working (per period)"
    utilFixed :: F1
end


"""
    $(SIGNATURES)

Worker object for one school group.
Most calibrated parameters are shared across school groups
(except wage).
Worker does not directly contain calibrated params (no ParamVector).
Ages are model ages.
"""
mutable struct Worker{F1 <: AbstractFloat}
    # Utility from consumption
    util :: WorkerUtility
    "Experience log wage profile. Zero intercept."
    xp :: Vector{F1}

    wage :: F1
    "Gross interest rate"
    R :: F1
    "First model age of retirement"
    retireAge :: TimeInt
    retireDuration :: TimeInt
    retireIncome :: F1
end


# Alias for vector with worker object for each school level
# Can now be indexed with integers or with EdLevels (e.g. HSG)
# const WorkerVector  = VectorBySchool{Worker}


"""
	$(SIGNATURES)

Switches that define a `WorkerSet`.
"""
Base.@kwdef mutable struct WorkerSetSwitches
    # Does the model have fixed utility from working by schooling?
    hasUFixed :: Bool = true
    retireAge :: TimeInt = 65 - 19
    retireDuration :: TimeInt = 80 - 65
    nSchool :: Int
end


"""
	$(SIGNATURES)

ModelObject with calibrated worker parameters.
"""
Base.@kwdef mutable struct WorkerSet{F1 <: AbstractFloat} <: ModelObject
    objId :: ObjectId
    switches :: WorkerSetSwitches
    "Log Wage by schooling"
    wages :: IncreasingVector
    "Experience log wage profile. Zero intercept."
    xp :: Vector{F1}
end


"""
	$(SIGNATURES)

Simulated work histories.
"""
mutable struct WorkHistories{F1 <: AbstractFloat}
    iSchoolV :: Vector{UInt8}
    "Age of work start"
    workStartAgeV :: Vector{TimeInt}
    hWorkStartV :: Vector{F1}
    kWorkStartV :: Vector{F1}
    "Earnings at work start"
    earnWorkStartV :: Vector{F1}
    "Lifetime earnings, discounted to work start"
    ltEarnV :: Vector{F1}
    "Marginal utility of wealth as of work start"
    muWealthV :: Vector{F1}
    "Consumption at work start"
    cWorkStartV :: Vector{F1}
end


# ---------------