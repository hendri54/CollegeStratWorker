# ----------------------  Worker

function make_test_worker(s :: Integer)
    uFct = make_test_worker_utility();
    retireAge = TimeInt(45);
    retireDuration = TimeInt(15);
    wage = 3.5 + Int(s);
    retireIncome = 0.5 * wage;
    R = 1.04;
    xp = collect(range(0.0, 0.6, length = retireAge));
    kMin = -20.0;
    kMax = 75.0;
    hMin = 1.0;
    hMax = 9.5;
    return Worker(uFct, xp, wage, R, retireAge, retireDuration, retireIncome,
        kMin, kMax, hMin, hMax)
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

k_range(wk :: Worker) = (wk.kMin, wk.kMax);
h_range(wk :: Worker) = (wk.hMin, wk.hMax);
k_min(wk :: Worker) = wk.kMin;
k_max(wk :: Worker) = wk.kMax;
h_min(wk :: Worker) = wk.hMin;
h_max(wk :: Worker) = wk.hMax;

# Life-span of a worker with work start 1
max_life_span(wk :: Worker) = wk.retireAge + wk.retireDuration - 1;
retire_periods(wk :: Worker, workStartAge) = wk.retireDuration;

# These ages are relative to `workStartAge`
life_span(wk :: Worker, workStartAge) = 
    work_periods(wk, workStartAge) .+ retire_periods(wk, workStartAge);
cons_periods(wk :: Worker, workStartAge) = life_span(wk, workStartAge);

last_work_age(wk :: Worker, workStartAge) = 
    wk.retireAge .- workStartAge;
work_periods(wk :: Worker, workStartAge) = last_work_age(wk, workStartAge);
work_ages(wk :: Worker, workStartAge) = 1 : last_work_age(wk, workStartAge);
# Retirement ages (relative to workStartAge)
retire_ages(wk :: Worker, workStartAge) = 
    last_work_age(wk, workStartAge) .+ (1 : retire_periods(wk, workStartAge));

# Input: ages relative to workStartAge
# is_retired(wk :: Worker, workStartAge :: Integer, tV) = 

# function retire_income(wk :: Worker{F1}, workStartAge :: Integer, tV) where F1
#     trV = retire_ages(wk, workStartAge);
#     incomeV = zeros(F1, size(tV)...);
#     incomeV[is_retired(wk, workStartAge, tV)] .= wk.retireIncome;
#     return incomeV
# end

# Present value of retirement income, discounted to workStartAge
function pv_retire_income(wk :: Worker, workStartAge)
    tV = retire_ages(wk, workStartAge);
    pv = retire_income(wk) * pv_factor(wk.R, length(tV));
    pv *= ((1 / wk.R) ^ (tV[1] - 1));
    return pv
end

retire_income(wk :: Worker) = wk.retireIncome;


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
# Does not include retirement income
function earn_profile(wk :: Worker{F1}, workStartAge :: Integer, h :: F1;
    experV = nothing) where F1

    earnV = h .* wk.wage .* exper_profile(wk, workStartAge; experV = experV);
    return earnV
end


"""
    $(SIGNATURES)

Lifetime earnings for a vector of h. Discounted to `workStartAge`.
Does not include retirement income.
"""
function lifetime_earnings(w :: Worker{F1}, workStartAge :: Integer, 
    h :: AbstractArray{F1}) where F1

    # T = work_periods(w, workStartAge);
    # This way it works for array `h` inputs.
    lty = h .* present_value(earn_profile(w, workStartAge, 1.0), w.R);
    @assert all(lty .> 0.0)  "Negative lifetime earnings"
    return lty
end

function lifetime_earnings(w :: Worker{F1}, workStartAge :: Integer, h :: F1) where F1
    lty = only(lifetime_earnings(w, workStartAge, [h]));
    @assert lty > 0.0
    return lty
end


# ---------------