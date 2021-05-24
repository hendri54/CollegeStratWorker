# no longer used +++++

function Base.show(io :: IO,  ws :: WorkerSet{F1}) where F1
    print(io,  "WorkerSet:",  ws.switches);
end


## ----------  Properties

ModelParams.has_pvector(wss :: WorkerSet) = false;

n_school(ws :: WorkerSet) = n_school(ws.switches);
n_school(wss :: WorkerSetSwitches) = wss.nSchool;

# Fixed utility while working
# Expressed as utility from fixed leisure
# Bad input argument +++
function u_fixed(ws :: WorkerSet{F1},  utilS,  s :: Integer) where F1
    if utilS.hasWorkLeisure
        u = UtilityFunctionsLH.CRRA(utilS.lCurvature, true);
        util = utilS.wtLeisure .* UtilityFunctionsLH.utility(u, utilS.leisure_sV[s]);
    else
        util = zero(F1);
    end
    return util 
end

function wage_by_school(ws :: WorkerSet)
	return exp.(ModelParams.values(ws.wages))
end

function wage(ws :: WorkerSet, s :: Integer)
    return wage_by_school(ws)[s]
end


## ---------------  Constructors

"""
	$(SIGNATURES)

Constructs the worker set from switches and experience profile.
"""
function make_worker_set(objId :: ObjectId, wss :: WorkerSetSwitches, xpProfileV :: Vector{F1}) where F1 <: AbstractFloat
    # objId = make_child_id(model_id(),  :workerSet);
    # Assumes that all experience profiles are the same +++
    # xp = exper_profile(ds, HSG, T = wss.retireAge);
    wages = init_wages(make_child_id(objId, :wages), n_school(wss));

    # pvec = worker_set_pvector(objId, wss, uS);
    
    ws = WorkerSet(objId = objId, switches = wss,
        wages = wages, xp = xpProfileV[1 : wss.retireAge]);
    return ws
end


function make_test_worker_set(wss :: WorkerSetSwitches)
    return make_worker_set(ObjectId(:workerSet), wss, 
        collect(range(0.0, 0.6, length = 70)))
end


# Log Wages by schooling (for workers)
    # change for wage object +++++
function init_wages(objId :: ObjectId, nSchool :: Integer)
    # This is a rough guess. The scale of human capital is on the order of 1
    # Starting wages of HSGs are only on the order of $10k; $20k for CGs (in Oksana's data).
    dataWageV = collect(range(10_000.0, 20_000.0, length = nSchool));
    # modelWageV = dollars_data_to_model(dataWageV, :perYear);
    modelWageV = dataWageV ./ 1000.0;  # +++
    logWageV = log.(modelWageV);
    ns = length(dataWageV);

    # Intercept and increments for `IncreasingVector`
    wageHSG = logWageV[1];
    wageInter = Param(:x0, "Log wage HSG", "wHSG",  
        wageHSG, wageHSG, wageHSG - 1.0, wageHSG + 0.5,  true);

    # dWageV = diff(logWageV);
    dWageV = fill(0.05, ns - 1);
    dWage = Param(:dxV, "Log wage gradient", "dw",
        dWageV, dWageV, fill(0.01, ns-1), fill(0.3, ns-1), true);

    # ownId = make_child_id(objId, :wages);
    pvec = ParamVector(objId = objId,  pv = [wageInter, dWage]);
    return IncreasingVector(objId, pvec,  wageHSG, dWageV)
end


"""
	$(SIGNATURES)

Make a worker. `s` is the school level.
"""
function make_worker(ws :: WorkerSet{F1},  utilS,  R :: F1,  s :: Integer) where F1
    # Log utility is handled by setting `uCurvature = 1.0`
    u = UtilityFunctionsLH.CRRA(utilS.cCurvature, true);
    uFct = WorkerUtility(u,  utilS.discFactor,  u_fixed(ws, utilS, s));
    retireIncome = zero(F1); # give workers retirement income +++
    kMin, kMax = k_range(ws);
    hMin, hMax = h_range(ws);
    return Worker(uFct, ws.xp, wage(ws, s), R, ws.switches.retireAge,
        ws.switches.retireDuration, retireIncome,
        kMin, kMax, hMin, hMax)
end


# ----------------