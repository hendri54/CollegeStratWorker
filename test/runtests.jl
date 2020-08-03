using CollegeStratWorker
using Random, Test
using ModelParams, UtilityFunctionsLH

const TimeInt = UInt8

# function experTest()
# 	@testset "Experience" begin
# 		xp = ExperProductivity(HSG);
# 		xV = collect(1:5);
# 		logProdV = log_exper_prod(xp, xV);
# 		@test length(logProdV) == length(xV)
# 		@test isa(logProdV, Vector{Double})
# 	end
# end

# Where to put this? +++++
# Base.@kwdef struct UtilAll{F1 <: AbstractFloat}
#     discFactor :: F1 = F1(0.9)
#     cCurvature :: F1 = F1(2.5)
#     lCurvature :: F1 = F1(1.5)
#     wtLeisure :: F1 = F1(0.6)
#     leisure_sV :: Vector{F1} = F1.([0.5, 0.1, 0.7, 1.2])
#     hasWorkLeisure :: Bool = true
# end

# function make_test_util_all()
#     return UtilAll{Float64}(discFactor = 0.9)
# end


function earnings_test()
	@testset "Lifetime earnings" begin
		w = CollegeStratWorker.make_test_worker(2);
        @test validate_worker(w);
        println("\n-------------")
		println(w);

		xV = log_exper_profile(w, 1; experV = 1 : 10);
		@test xV[1] ≈ 0.0
		@test all(diff(xV) .> 0.0)
		# Giving work start age
		x2V = log_exper_profile(w, 5);

		workStartAge = 3;
		h0 = 1.5;
		earn10 = earn_profile(w, workStartAge, h0, experV = 10);
		@test earn10 > 0.0
		@test isa(earn10, AbstractFloat)

		xpV = 7 : 15;
		earnV = earn_profile(w, workStartAge, h0, experV = xpV);
		@test all(earnV .> 0.0)
		@test size(earnV) == size(xpV)

		hM = [2.0 3.0 4.0; 0.6 0.7 0.8];
		workStartAge = 2;
		ltyV = lifetime_earnings(w, workStartAge, hM);
		@test all(ltyV .> 0) && (size(ltyV) == size(hM))

		lty2V = lifetime_earnings(w, workStartAge + 1, hM);
		@test all(lty2V .< ltyV)
	end
end

function utility_test()
	@testset "Lifetime utility" begin
		w = CollegeStratWorker.make_test_worker(3);
        println("\n-------------")
		println(w);

        # Lifetime utility
		hV = [1.8, 2.3];
		assetV = [-0.7, 0.9, 3.2];
		workStartAge = 3;

		# On a grid
		utilM = lifetime_utility_grid(w, workStartAge, assetV, hV);
		@test size(utilM) == (length(assetV), length(hV))
		# Increasing in h
		@test all(utilM[:,2] .> utilM[:,1])
		# Increasing in assets
		util2M = lifetime_utility_grid(w, workStartAge, assetV .+ 0.001, hV);
		@test all(util2M .> utilM)

		# Test against state by state
		util3M = similar(utilM);
		for (ih, h) in enumerate(hV)
            for (ia, a) in enumerate(assetV)
                # Must be qualified b/c exported by two packages
				util3M[ia, ih] = CollegeStratWorker.lifetime_utility(w, workStartAge, assetV[ia], hV[ih]);
			end
		end
		@test all(util3M .≈ utilM)

		# Vector
		h2V = fill(hV[1], length(assetV));
		util3V = lifetime_utility_vector(w, workStartAge, assetV, h2V);
		@test all(util3V .≈ utilM[:, 1])

		# MU wealth
		ltIncome = [1.2 2.3; 3.4 4.5];
		mu = CollegeStratWorker.mu_wealth(w, workStartAge, ltIncome);
		@test size(ltIncome) == size(mu)
		@test all(mu .> 0.0)

		# Consumption at age 1
		c1 = CollegeStratWorker.cons_age1(w, workStartAge, ltIncome);
		@test size(c1) == size(ltIncome)
		@test all(c1 .> 0.0)
    end
end


# function worker_set_test()
#     @testset "WorkerSet" begin
#         nSchool = 4;
# 		wss = WorkerSetSwitches(nSchool = nSchool);
# 		ws = CollegeStratWorker.make_test_worker_set(wss);
# 		utilS = make_test_util_all();
# 		R = 1.04;
#         iSchool = 2;

# 		# Fixed utilities
# 		uFixed = u_fixed(ws, utilS, iSchool);
# 		@test isa(uFixed, Float64)

# 		# Wages
# 		wage_sV = wage_by_school(ws);
# 		# @test length(wage_sV) == nSchool
# 		@test wage(ws, iSchool) ≈ wage_sV[iSchool]

# 		# Make worker
# 		wk = make_worker(ws, utilS, R, iSchool);
# 		print(wk)
# 		@test validate_worker(wk)
# 	end
# end


function simulate_test()
    @testset "Simulation" begin
        rng = MersenneTwister(43);
        nSchool = 4;
        nSim = 11;
        iSchoolV = rand(rng, UInt8.(1 : nSchool), nSim);
        workStartAgeV = rand(rng, TimeInt.(1:5), nSim);
        hWorkStartV = 1.0 .+ 2.0 .* rand(rng, nSim);
        kWorkStartV = rand(rng, nSim) .- 0.1;

        wh = WorkHistories(iSchoolV, workStartAgeV, hWorkStartV, kWorkStartV);
        println("\n--------------")
        println(wh);

        @test length(wh) == nSim
        @test isequal(school_index(wh), iSchoolV)
        @test isequal(work_start_ages(wh), workStartAgeV)
        @test isequal(h_work_start(wh), hWorkStartV)
        @test isequal(k_work_start(wh), kWorkStartV)

		# wss = WorkerSetSwitches(nSchool = nSchool);
		# ws = CollegeStratWorker.make_test_worker_set(wss);
		# utilS = make_test_util_all();
		R = 1.04;
		workerV = [CollegeStratWorker.make_test_worker(iSchool)  for iSchool = 1 : nSchool];

        simulate_workers!(wh, workerV);
        @test validate_wh(wh)
    end
end


@testset "Worker" begin
	earnings_test();
	utility_test();
	include("compensating_var_test.jl");
    # worker_set_test();
    simulate_test();
end

# --------------