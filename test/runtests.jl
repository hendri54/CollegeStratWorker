using CollegeStratBase, CollegeStratWorker
using Random, Test
using ModelParams, UtilityFunctionsLH

const TimeInt = UInt8

csw = CollegeStratWorker;

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


function access_test()
	@testset "Access routines" begin
		wk = csw.make_test_worker(2);
		@test csw.max_life_span(wk) == csw.life_span(wk, 1)

		workStartAge = 3;
		nc = csw.cons_periods(wk, workStartAge);
		nWork = csw.work_periods(wk, workStartAge);
		nRetire = csw.retire_periods(wk, workStartAge);
		@test nc == (nWork + nRetire)

		workAgeV = csw.work_ages(wk, workStartAge);
		retireAgeV = csw.retire_ages(wk, workStartAge);
		@test length(workAgeV) == nWork;
		@test length(retireAgeV) == nRetire;
		@test workAgeV[nWork] + 1 == retireAgeV[1];
		@test csw.last_work_age(wk, workStartAge) == workAgeV[nWork];
	end
end

function earnings_test()
	@testset "Lifetime earnings" begin
		wk = CollegeStratWorker.make_test_worker(2);
        @test validate_worker(wk);
        println("\n-------------")
		println(wk);

		xV = log_exper_profile(wk, 1; experV = 1 : 10);
		@test xV[1] ≈ 0.0
		@test all(diff(xV) .> 0.0)
		# Giving work start age
		x2V = log_exper_profile(wk, 5);

		workStartAge = 3;
		h0 = 1.5;
		earn10 = earn_profile(wk, workStartAge, h0, experV = 10);
		@test earn10 > 0.0
		@test isa(earn10, AbstractFloat)

		xpV = 7 : 15;
		earnV = earn_profile(wk, workStartAge, h0, experV = xpV);
		@test all(earnV .> 0.0)
		@test size(earnV) == size(xpV)

		hM = [2.0 3.0 4.0; 0.6 0.7 0.8];
		workStartAge = 2;
		ltyV = lifetime_earnings(wk, workStartAge, hM);
		@test all(ltyV .> 0) && (size(ltyV) == size(hM))

		for (j, h) in enumerate(hM)
			lty2 = present_value(earn_profile(wk, workStartAge, h), wk.R);
			@test isapprox(lty2, ltyV[j])
		end

		lty2V = lifetime_earnings(wk, workStartAge + 1, hM);
		@test all(lty2V .< ltyV)

		# Retirement income
		T = csw.life_span(wk, workStartAge);
		incomeV = zeros(T);
		incomeV[csw.retire_ages(wk, workStartAge)] .= csw.retire_income(wk);
		pv = present_value(incomeV, wk.R);
		@test isapprox(pv, csw.pv_retire_income(wk, workStartAge));
	end
end



function consumption_test()
	@testset "Consumption" begin
		w = csw.make_test_worker(3);
		workStartAge = 2;
		ltIncome = [3.4 2.1; 9.2 4.7];
		# Consumption at age 1
		c1 = csw.cons_age1(w, workStartAge, ltIncome);
		@test size(c1) == size(ltIncome)
		@test all(c1 .> 0.0)

		lty = 3.9;
		ltyTotal = lty + csw.pv_retire_income(w, workStartAge);
		c1 = csw.cons_age1(w, workStartAge, lty);
		cV = csw.cons_path(w, workStartAge, lty);
		@test length(cV) == csw.cons_periods(w, workStartAge);
		@test isapprox(cV[1], c1)
		@test isapprox(present_value(cV, w.R), ltyTotal)
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

		wh2 = csw.make_test_work_histories(nSchool, nSim);
		@test validate_wh(wh2);
    end
end


@testset "Worker" begin
	access_test();
	earnings_test();
	consumption_test();
	include("lifetime_utility_test.jl");
	include("compensating_var_test.jl");
    # worker_set_test();
    simulate_test();
end

# --------------