# -------------  Lifetime utility


"""
	$(SIGNATURES)

Lifetime utility as a function of lifetime income (earnings + assets).
NOT counting retirement income.
Gives minimum consumption to make negative incomes feasible.
"""
function lifetime_utility(w :: Worker,  workStartAge :: Integer, ltIncome)
    T = cons_periods(w, workStartAge);
    util = lifetime_utility(w.util, T, w.R, ltIncome .+ pv_retire_income(w, workStartAge));
    return util
end


"The same for single asset and h values."
function lifetime_utility(w :: Worker{F1}, workStartAge :: Integer,
    asset :: F1, h :: F1) where F1

    ltEarn = lifetime_earnings(w, workStartAge, h);
    util = lifetime_utility(w, workStartAge, asset .+ ltEarn);
    return util
end


"""
	$(SIGNATURES)

Lifetime utility as a vector.
"""
function lifetime_utility_vector(w :: Worker{F1}, workStartAge :: Integer,
    assetV :: Vector{F1}, hV :: Vector{F1}) where F1

    nh = length(hV);
        # @assert length(assetV) == length(hV)

    ltIncomeV = lifetime_earnings(w, workStartAge, hV) .+ assetV;
    utilV = Vector{F1}(undef, nh);
    for ih in 1 : nh
        utilV[ih] = lifetime_utility(w, workStartAge, ltIncomeV[ih]);
    end
    return utilV
end


"""
    $(SIGNATURES)

Lifetime utility on a GRID for assets, h.
Gives arbitrary small amount to those with negative lifetime incomes (useful when solving with poor parameter guesses).
"""
function lifetime_utility_grid(w :: Worker{F1}, workStartAge :: Integer, 
    assetV :: Vector{F1}, hV :: Vector{F1}) where F1

    nh = length(hV);
    na = length(assetV);

    ltEarnV = lifetime_earnings(w, workStartAge, hV);

    util_ahM = zeros(F1, na, nh);
    for ih in 1 : nh
        for ia in 1 : na
            util_ahM[ia, ih] = lifetime_utility(w, 
                workStartAge, max(0.1, ltEarnV[ih] + assetV[ia]));
        end
    end

    @assert all(x -> x > F1(-1e6), util_ahM) "Low lifetime utility"
    return util_ahM
end


"""
	$(SIGNATURES)

Marginal utility of lifetime income (or assets).
`ltIncome` omits retirement income.
"""
function mu_wealth(wk :: Worker, workStartAge :: Integer, ltIncome)
    return mu_wealth(wk.util, cons_periods(wk, workStartAge), wk.R, 
        ltIncome .+ pv_retire_income(wk, workStartAge))
end


function mu_wealth(wk :: Worker{F1}, workStartAge :: Integer,
    asset :: F1, h :: F1) where F1

    ltEarn = lifetime_earnings(wk, workStartAge, h);
    return mu_wealth(wk, workStartAge, asset .+ ltEarn);
end


## Consumption at age 1
# Lifetime income excludes retirement income.
function cons_age1(wk :: Worker,  workStartAge :: Integer,  ltIncome)
    return cons_age1(wk.util, cons_periods(wk, workStartAge), wk.R, 
        ltIncome .+ pv_retire_income(wk, workStartAge))
end

# --------------