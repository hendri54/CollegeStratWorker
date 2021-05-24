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
    assetV :: AbstractVector{F1}, hV :: AbstractVector{F1}) where F1

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

Make a continuous function that gives lifetime utility as a function of assets and h at work start.
"""
function lifetime_utility_function(wk :: Worker{F1}, 
    workStartAge :: Integer;
    kMin = k_min(wk), kMax = k_max(wk), 
    hMin = h_min(wk), hMax = h_max(wk),
    nk = 500, nh = 100) where F1

    kGridV = asset_grid(kMin, kMax, nk);
    hGridV = h_grid(hMin, hMax, nh);
    util_ahM = lifetime_utility_grid(wk, workStartAge, kGridV, hGridV);
    # f = CubicSplineInterpolation((kGridV, hGridV), util_ahM);
    # The long way round construction supports `bounds`
    f = scale(interpolate(util_ahM, BSpline(Cubic(Line(OnGrid())))), kGridV, hGridV);
    return f
end

# Must return a `range` for `Interpolations.jl` to work.
asset_grid(kMin, kMax, nk) = LinRange(kMin, kMax, nk);
h_grid(kMin, kMax, nh) = LinRange(kMin, kMax, nh);


"""
	$(SIGNATURES)

Compute deviation between interpolated and true worker lifetime utility on a (k, h) grid.
"""
function interpolation_deviation(wk :: Worker, workStartAge :: Integer, f;
    nk = 10, nh = 10)
    maxDev = 0.0;
    kRange, hRange = f.ranges;
    kGrid = grid_from_range(kRange; n = nk);
    hGrid = grid_from_range(hRange; n = nh);
    for h in hGrid
        for k in kGrid
            u = lifetime_utility(wk, workStartAge, k, h); 
            u2 = f(k, h);
            dev = abs(u2 - u) / max(1.0, abs(u));
            maxDev = max(dev, maxDev);
        end
    end
    return maxDev
end

# function interpolation_deviation_one(wk :: Worker, workStartAge)


"""
	$(SIGNATURES)

Return worker lifetime utility on the grid used to construct the interpolation.

But the grids are offset so the interval midpoints are used. To assess accuracy of approximation.
"""
function lifetime_utility_function_grid(f)
    kRange, hRange = f.ranges;
    kGrid = grid_from_range(kRange);
    hGrid = grid_from_range(hRange); 
    u = zeros(length(kGrid), length(hGrid));
    for (i_h, h) in enumerate(hGrid)
        for (i_k, k) in enumerate(kGrid)
            u[i_k, i_h] = f(k, h); 
        end
    end
    return u, kGrid, hGrid
end

# Grid with points half way between the grid points used to construct interpolation.
# For checking accuracy.
function grid_from_range(r; n = length(r) - 1)
    # n = length(r) - 1;
    d = last(r) - first(r);
    dGrid = d / n;
    grid = (first(r) + 0.5 * dGrid) : dGrid : last(r);
    return grid
end


function make_test_lifetime_utility_function(
    workStartAge :: Integer, iSchool :: Integer;
    kMin = -50.0, kMax = 50.0, hMin = 1.0, hMax = 5.0)
    wk = make_test_worker(iSchool);
    v = lifetime_utility_function(wk, workStartAge);
        # kMin = kMin, kMax = kMax, hMin = hMin, hMax = hMax);
    return v
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

# Lifetime income excludes retirement income.
function cons_path(wk :: Worker, workStartAge, ltIncome)
    return cons_path(wk.util, 
        cons_periods(wk, workStartAge), wk.R, 
        ltIncome .+ pv_retire_income(wk, workStartAge))
end


# --------------