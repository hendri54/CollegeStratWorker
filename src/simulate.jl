# function WorkHistories(F1 :: DataType, nSim :: Integer)
#     return WorkHistories(
#         zeros(UInt8, nSim),
#         zeros(TimeInt, nSim), 
#         zeros(F1, nSim), zeros(F1, nSim), 
#         zeros(F1, nSim), zeros(F1, nSim), 
#         zeros(F1, nSim), zeros(F1, nSim)
#     )
# end

function WorkHistories(iSchoolV :: Vector{UInt8}, 
    workStartAgeV :: Vector{TimeInt}, 
    hWorkStartV :: Vector{F1}, kWorkStartV :: Vector{F1}) where F1 <: AbstractFloat

    nSim = length(iSchoolV);
    return WorkHistories(
        iSchoolV, workStartAgeV, hWorkStartV, kWorkStartV,
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

    # nSim = length(cResults);
    # wh = WorkHistories(nSim);

    # sIdxV = school_index(cResults);
    # wh.workStartAgeV = work_start_age(cResults);
    startAgeV = unique(wh.workStartAgeV);

    for iSchool = 1 : n_school(wh)
        wk = workerV[iSchool];
        for workStartAge in startAgeV
            # more efficient ++++++
            # idxV = findall((s,a) -> ((s == iSchool)  &&  (a == workStartAge)), 
            #     (school_index(wh), work_start_ages(wh)));
            idxV = (school_index(wh) .== iSchool) .& 
                (work_start_ages(wh) .== workStartAge);
            if !isempty(idxV)
                # Earnings at work start
                # Earnings profile, up to `h` factor
                earnWorkStart = earn_profile(wk, workStartAge, 1.0; experV = 1);
                wh.earnWorkStartV[idxV] = h_work_start(wh)[idxV] .* earnWorkStart;

                wh.ltEarnV[idxV] .= lifetime_earnings(wk, workStartAge, 
                    h_work_start(wh)[idxV]);
                # Bound below in case we have bad parameter values during testing
                ltIncomeV = max.(0.1, wh.ltEarnV[idxV] .+ k_work_start(wh)[idxV]);
                # Consumption at work start
                wh.cWorkStartV[idxV] .= cons_age1(wk, workStartAge, ltIncomeV);
                # Marginal utility of wealth as of work start
                wh.muWealthV[idxV] .= mu_wealth(wk, workStartAge, ltIncomeV);
            end
        end
    end

    @assert validate_wh(wh)
    return nothing
end

# ----------------