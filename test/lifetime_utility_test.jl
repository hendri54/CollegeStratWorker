function utility_test()
	@testset "Lifetime utility" begin
		w = CollegeStratWorker.make_test_worker(3);
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
		# Test by perturbation
		dy = 1e-5;
		util1M = [csw.lifetime_utility(w, workStartAge, lty)  for lty in ltIncome];
		util2M = 
			[csw.lifetime_utility(w, workStartAge, lty .+ dy)  for lty in ltIncome];
		muM = (util2M .- util1M) ./ dy;
		@test all(muM .> 0.0)
		@test isapprox(muM, mu, rtol = 1e-3)
	end
end

function lt_util_fct_test()
	@testset "Lifetime Utility Function" begin
		wk = CollegeStratWorker.make_test_worker(3);
		workStartAge = 3;
		nk = 30;
		nh = 20;
		kGridV = LinRange(-10.0, 25.0, nk);
		hGridV = LinRange(1.2, 4.7, nh);
		f = lifetime_utility_function(wk, workStartAge; 
			kMin = first(kGridV), kMax = last(kGridV),
			hMin = first(hGridV), hMax = last(hGridV));

		for ik = 2 : 3 : (nk-1)
			for ih = 2 : 4 : (nh-1)
				k = kGridV[ik] + 0.3;
				h = hGridV[ih] - 0.1;
				u1 = f(k, h);
				u2 = csw.lifetime_utility(wk, workStartAge, k, h);
				@test isapprox(u1, u2, rtol = 1e-3);
			end
		end

        dev = interpolation_deviation(wk, workStartAge, f);
        @test dev > 0
        @test dev < 1e-3

        uGrid, kGrid, hGrid = lifetime_utility_function_grid(f);
        uGrid2 = lifetime_utility_grid(wk, workStartAge, kGrid, hGrid);
        dev2 = maximum(abs.(uGrid2 .- uGrid) ./ max.(1.0, abs.(uGrid)));
        @test dev2 < 1e-3
	end
end

@testset "Lifetime utility" begin
	utility_test();
	lt_util_fct_test();
end

# -------------