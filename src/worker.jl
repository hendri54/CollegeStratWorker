# ----------------------  Worker

function make_test_worker(s :: Integer)
    uFct = make_test_worker_utility();
    retireAge = TimeInt(45);
    retireDuration = TimeInt(15);
    wage = 3.5 + Int(s);
    retireIncome = 0.5 * wage;
    R = 1.04;
    xp = collect(range(0.0, 0.6, length = retireAge));
    return Worker(uFct, xp, wage, R, retireAge, retireDuration, retireIncome)
end


function validate_worker(wk :: Worker)
    isValid = (wk.wage > 0.0)  &&  (wk.R > 0.9)  &&  (wk.retireDuration > 5);
    if !(wk.xp[1] ≈ 0.0)
        @warn "Experience at t = 1 should be 0"
        isValid = false;
    end
    return isValid
end


## ---------------  Show

function settings_table(wk :: Worker)
    maxExper, maxAge = findmax(wk.xp);
    maxExper = round(maxExper, digits = 2);
    return [
        "Worker"  " ";
        "Retirement age"  "$(wk.retireAge)";
        "Retirement duration"  "$(wk.retireDuration)";
        "Max log experience"  "$maxExper at age $maxAge"
    ]
end

StructLH.describe(wk :: Worker) = settings_table(wk);


# function show(io :: IO,  wk :: Worker)
#     show_text_table(settings_table(wk), io = io)
# end

function Base.show(io :: IO,  wk :: Worker)
    wageStr = string(round(wk.wage, digits = 2));
    maxExper, maxAge = findmax(wk.xp);
    maxExper = round(maxExper, digits = 2);
    print(io, "Worker:")
    println(io, "  Wage: $wageStr    retireAge: $(wk.retireAge)");
    println(io, "  Max log experience $maxExper at exper $maxAge")
    return nothing
end


## -----------  Access properties

function work_periods(wk :: Worker, workStartAge)
    return wk.retireAge .- workStartAge
end

function cons_periods(wk :: Worker, workStartAge)
    return work_periods(wk, workStartAge) .+ wk.retireDuration
end

# Retirement ages (relative to workStartAge)
function retire_ages(wk :: Worker, workStartAge)
    return work_periods(wk, workStartAge) .+ (1 : wk.retireDuration)
end


# Present value of retirement income, discounted to workStartAge
# test this +++++
function pv_retire_income(wk :: Worker, workStartAge)
    tV = retire_ages(wk, workStartAge);
    return wk.retireIncome .* sum((1 / wk.R) .^ (tV .- 1));
end


"""
	$(SIGNATURES)

Log experience productivity profile for given workStartAge until retirement.
Normalized to 1 at work start.

# Arguments
- `experV`: experience levels; work start age is 1.
"""
function log_exper_profile(wk :: Worker, workStartAge :: Integer; 
    experV = nothing)
    T = work_periods(wk, workStartAge);
    @assert T > 0
    if isnothing(experV)
        return wk.xp[1 : T]
    else
        return wk.xp[experV]
    end
end


"""
	$(SIGNATURES)

Experience-wage profile. Normalized to 1 at work start.
"""
function exper_profile(wk :: Worker{F1}, workStartAge :: Integer; experV = nothing) where F1
    return exp.(log_exper_profile(wk, workStartAge; experV = experV))
end


# Earnings profile by experience
function earn_profile(wk :: Worker{F1}, workStartAge :: Integer, h :: F1;
    experV = nothing) where F1

    earnV = h .* wk.wage .* exper_profile(wk, workStartAge; experV = experV);
    return earnV
end


"""
    $(SIGNATURES)

Lifetime earnings for a vector of h. Discounted to `workStartAge`.
"""
function lifetime_earnings(w :: Worker{F1}, workStartAge :: Integer, h :: Array{F1}) where F1

    T = work_periods(w, workStartAge);
    lty = h .* sum(((1 / w.R) .^ (0 : (T - 1))) .*
        earn_profile(w, workStartAge, 1.0));
    @assert all(lty .> 0.0)  "Negative lifetime earnings"
    return lty
end

function lifetime_earnings(w :: Worker{F1}, workStartAge :: Integer, h :: F1) where F1
    lty = lifetime_earnings(w, workStartAge, [h]);
    @assert lty[1] > 0.0
    return lty[1]
end


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


# ---------------