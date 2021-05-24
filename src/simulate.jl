"""
	$(SIGNATURES)

Initialize an empty, preallocated `WorkHistories` object.
"""
function WorkHistories(F1 :: DataType, nSim :: Integer)
    return WorkHistories(
        zeros(UInt8, nSim),
        zeros(TimeInt, nSim), 
        zeros(F1, nSim), zeros(F1, nSim), 
        zeros(F1, nSim), zeros(F1, nSim), 
        zeros(F1, nSim), zeros(F1, nSim)
    )
end


"""
	$(SIGNATURES)

Create `WorkHistories` with work start endowments filled in.
"""
function WorkHistories(iSchoolV, workStartAgeV, 
    hWorkStartV :: Vector{F1}, kWorkStartV :: Vector{F1}) where F1 <: AbstractFloat

    nSim = length(iSchoolV);
    return WorkHistories(
        UInt8.(iSchoolV), TimeInt.(workStartAgeV), hWorkStartV, kWorkStartV,
        zeros(F1, nSim), zeros(F1, nSim), 
        zeros(F1, nSim), zeros(F1, nSim)
    )
end

Base.show(io :: IO, wh :: WorkHistories{F1}) where F1 =
    print(io, "WorkHistories of length $(length(wh)).")

Base.length(wh :: WorkHistories) = length(wh.workStartAgeV);
school_index(wh :: WorkHistories) = wh.iSchoolV;
work_start_ages(wh :: WorkHistories) = wh.workStartAgeV;
h_work_start(wh :: WorkHistories{F1}) where F1 = wh.hWorkStartV;
k_work_start(wh :: WorkHistories{F1}) where F1 = wh.kWorkStartV;
n_school(wh :: WorkHistories) = maximum(school_index(wh));


function validate_wh(wh :: WorkHistories{F1}) where F1
    isValid = true;
    if any_less(wh.workStartAgeV, 1)  ||  any_greater(wh.workStartAgeV, 9)
        isValid = false;
        @warn "Invalid work start ages"
    end
    if any_at_most(wh.earnWorkStartV, zero(F1))
        isValid = false;
        @warn "Earnings at work start should be positive"
    end
    if any_at_most(wh.ltEarnV, zero(F1))
        isValid = false;
        @warn "Lifetime earnings should be positive"
    end
    if any_at_most(wh.cWorkStartV, zero(F1))
        isValid = false
        @warn "Negative consumption at work start"
    end
    if any_at_most(wh.muWealthV, zero(F1))
        isValid = false;
        @warn "Negative marginal utility of wealth"
    end
    return isValid
end


"""
	$(SIGNATURES)

Simulate work histories. Input are `WorkHistories` that are initialized with workers' initial conditions: work start age, schooling, initial h and k.
"""
function simulate_workers!(wh :: WorkHistories{F1}, 
    workerV :: Vector{Worker{F1}}) where F1

    for iSchool = 1 : n_school(wh)
        sIdxV = findall(s -> s == iSchool,  school_index(wh));
        if !isempty(sIdxV)
            simulate_one_worker!(wh, workerV[iSchool], sIdxV);
        end
    end

    @assert validate_wh(wh)
    return nothing
end


"""
	$(SIGNATURES)

Simulate workers for one school level. Workers in rows `sIdxV`.
"""
function simulate_one_worker!(wh :: WorkHistories{F1}, wk :: Worker{F1}, 
    sIdxV :: AbstractVector{I1}) where {F1 <: AbstractFloat, I1 <: Integer}

    startAgeV = unique(wh.workStartAgeV[sIdxV]);
    for workStartAge in startAgeV
        idxV = findall(a -> a == workStartAge, work_start_ages(wh)[sIdxV]);
        simulate_one_work_start!(wh, wk, workStartAge, sIdxV[idxV]);
    end
    return nothing
end


# Work start age must be common to all
function simulate_one_work_start!(wh :: WorkHistories{F1}, wk :: Worker{F1}, 
    workStartAge :: Integer, idxV :: AbstractVector{I1}) where {F1 <: AbstractFloat, I1 <: Integer}

    # Earnings at work start
    # Earnings profile, up to `h` factor
    earnWorkStart = earn_profile(wk, workStartAge, 1.0; experV = 1);
    wh.earnWorkStartV[idxV] .= h_work_start(wh)[idxV] .* earnWorkStart;

    wh.ltEarnV[idxV] .= lifetime_earnings(wk, workStartAge, 
        h_work_start(wh)[idxV]);
    # Bound below in case we have bad parameter values during testing
    ltIncomeV = max.(0.1, wh.ltEarnV[idxV] .+ k_work_start(wh)[idxV]);
    # Consumption at work start
    wh.cWorkStartV[idxV] .= cons_age1(wk, workStartAge, ltIncomeV);
    # Marginal utility of wealth as of work start
    wh.muWealthV[idxV] .= mu_wealth(wk, workStartAge, ltIncomeV);
    return nothing
end


function make_test_work_histories(nSchool :: Integer, nSim :: Integer)
    rng = MersenneTwister(43);
    iSchoolV = rand(rng, UInt8.(1 : nSchool), nSim);
    workStartAgeV = rand(rng, TimeInt.(1:5), nSim);
    hWorkStartV = 1.0 .+ 2.0 .* rand(rng, nSim);
    kWorkStartV = rand(rng, nSim) .- 0.1;
    earnWorkStartV = 9.0 .+ 3.0 .* rand(rng, nSim);
    ltEarnV = 10.5 .* earnWorkStartV;
    muWealthV = 5.0 ./ earnWorkStartV;
    cWorkStartV = 0.7 .* earnWorkStartV;

    wh = WorkHistories(iSchoolV, workStartAgeV, hWorkStartV, kWorkStartV,
        earnWorkStartV, ltEarnV, muWealthV, cWorkStartV);
    @assert validate_wh(wh)  "Invalid Test work history"
    return wh
end

# ----------------