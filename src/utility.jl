function make_test_worker_utility()
    # `true` is debugging switch
    uFct = UtilityFunctionsLH.CRRA(2.0, true);
    return WorkerUtility(uFct, 0.97, 0.0)
end

function validate(u :: WorkerUtility{F1}) where F1
    return  (u.discFactor > 0.5)  &&  !isinf(u.utilFixed)
end

function Base.show(io :: IO, u :: WorkerUtility)
    betaStr = round(u.discFactor, digits = 3);
    uStr = round(u.utilFixed, digits = 2);
    print(io,  "WorkerUtility:  beta: $betaStr,  uFixed: uStr")
end

discount_factor(u :: WorkerUtility{F1}) where F1 = u.discFactor;
util_fixed(u :: WorkerUtility{F1}) where F1 = u.utilFixed;

## ---------------  Methods

"""
	$(SIGNATURES)

Lifetime utility for given lifetime income `ltIncome`, life-span `T`.
Includes fixed utility `utilFixed`.
"""
function lifetime_utility(u :: WorkerUtility{F1}, T :: Integer,  R :: F1, ltIncome) where F1
    pBeta = discount_factor(u);

    utilFixed = UtilityFunctionsLH.lifetime_utility(util_fixed(u), pBeta, T);
    utilFlow  = UtilityFunctionsLH.lifetime_utility(u.util, 
        pBeta, R, T, max.(0.0001, ltIncome));
    return utilFixed + utilFlow
end


"""
	$(SIGNATURES)

Marginal utility of wealth.
"""
function mu_wealth(u :: WorkerUtility{F1}, T :: Integer, R :: F1, ltIncome) where F1
    return UtilityFunctionsLH.mu_wealth(u.util, u.discFactor, R, T, ltIncome)
end


"""
	$(SIGNATURES)

Consumption at work start.
"""
function cons_age1(u :: WorkerUtility{F1}, T :: Integer, R :: F1, ltIncome) where F1
    return UtilityFunctionsLH.cons_age1(u.util, u.discFactor, R, T, ltIncome)
end


function cons_path(u :: WorkerUtility{F1}, T :: Integer, R :: F1, ltIncome) where F1
    return UtilityFunctionsLH.cons_path(u.util, u.discFactor, R, T, ltIncome)
end

# ----------------