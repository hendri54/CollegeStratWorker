"""
	$(SIGNATURES)

Compute pre-retirement lifetime income that gives a given level of utility. For many utility levels.
This is more efficient than computing one at a time because search bounds can be set intelligently.
When lifetime incomes are out of bounds: return the bounds.
"""
function ltincome_from_utility(wk :: Worker{F1}, workStartAge :: Integer, 
    ltUtilityV :: Vector{F1},  ltyLb :: F1,  ltyUb :: F1) where F1 <: AbstractFloat

    n = length(ltUtilityV);
    ltIncomeV = zeros(F1, n);

    # Sort lifetime incomes
    sortIdxV = sortperm(ltUtilityV);

    # Solve lowest and highest to get bounds
    j = sortIdxV[1];
    lb = ltyLb;
    ub = ltyUb;
    ltIncomeV[j] = ltincome_from_utility(wk, workStartAge, ltUtilityV[j], lb, ub);

    j = sortIdxV[n];
    lb = ltIncomeV[sortIdxV[1]];
    ltIncomeV[j] = ltincome_from_utility(wk, workStartAge, ltUtilityV[j], lb, ub);

    # Solve the rest using known cases as bounds
    # Determine order such that good bounds are always nearby.
    solveIdxV = sortIdxV[bisecting_indices(1, n)];
    for j = 3 : n
        idx = solveIdxV[j];
        ltUtil = ltUtilityV[idx];

        # Find first person already solved with utility above this one.
        idxUb = findfirst((ltUtilityV[sortIdxV] .> ltUtil)  .&  
            (ltIncomeV[sortIdxV] .> 0.0));
        @assert idxUb > 0
        idxUb = sortIdxV[idxUb];
        
        # Find last person already solved with utility below this one.
        idxLb = findlast((ltUtilityV[sortIdxV] .< ltUtil)  .&  
            (ltIncomeV[sortIdxV] .> 0.0));
        idxLb = sortIdxV[idxLb];
        ltIncomeV[idx] = ltincome_from_utility(wk, workStartAge, ltUtil,
            ltIncomeV[idxLb], ltIncomeV[idxUb]);
    end

    @assert all_greater(ltIncomeV, 0.01)
    return ltIncomeV
end


"""
	$(SIGNATURES)

Given a worker, find the pre-retirement lifetime income that gives a given level of utility.
This requires numerical root finding. So it will be slow.
Bounds for the search range are provided as inputs. If values are out of bounds, the bounds are returned. This only happens with poor parameter values (during calibration).
"""
function ltincome_from_utility(wk :: Worker{F1}, workStartAge :: Integer, 
    ltUtility :: F1, lb :: F1, ub :: F1) where F1

    dev_fct(x) = (lifetime_utility(wk, workStartAge, x) .- ltUtility);

    dLow = dev_fct(lb);
    if dLow >= 0.0  
        @warn "Lower bound too high: $lb for $ltUtility";
        return lb
    end

    dHigh = dev_fct(ub);
    if dHigh <= 0.0  
        @warn "Upper bound too low: $ub for $ltUtility";
        return ub
    end

    # optS = nlopt_init(dev_fct, lb, ub);
    # fVal, solnV, exitFlag = NLopt.optimize(optS, typicalLtIncome);
    ltOut = find_zero(dev_fct, (lb, ub));
    @assert lb ≤ ltOut ≤ ub

    ltu = lifetime_utility(wk, workStartAge, ltOut);
    @assert isapprox(ltu, ltUtility, atol = 0.01)
    return ltOut
end

# function nlopt_init(local_dev_fct, lbV, ubV)
#     nParams = 1;
#     optS = NLopt.Opt(,  nParams);
#     optS.min_objective = local_dev_fct;
#     optS.lower_bounds = lbV;
#     optS.upper_bounds = ubV;
#     optS.stopval = 0.001;
#     # Solver maxtime is seconds
#     # (s.maxHours > 0)  &&  (optS.maxtime = s.maxHours * 3600);
#     # Need to stop when f value changes little. Otherwise we get thousands of constant iterations.
#     optS.ftol_rel = 0.005;
#     optS.maxeval = 10_000;
#     return optS
# end

# -------------