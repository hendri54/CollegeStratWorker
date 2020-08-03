# Compensating variations
using CollegeStratWorker, Random, Test

csw = CollegeStratWorker;

function cv_test()
    @testset "Compensating variations" begin
        wk = csw.make_test_worker(2);
        ltIncome = 23.0;
        workStartAge = 3;
        ltuBase = csw.lifetime_utility(wk, workStartAge, ltIncome);
        @test !isinf(ltuBase)

        lb = ltIncome / 10.0;
        ub = ltIncome * 10.0;
        ltIncomeNew = csw.ltincome_from_utility(wk, workStartAge, ltuBase, lb, ub);
        @test ltIncomeNew > 0.0
        @test isapprox(ltIncome, ltIncomeNew, rtol = 0.001)

        # Solve many
        rng = MersenneTwister(43);
        n = 110;
        ltIncomeV = 1000.0 .+ rand(rng, n) .* 3000.0;
        ltUtilV = [csw.lifetime_utility(wk, workStartAge, ltIncomeV[j])  
            for j = 1 : n];
        ltIncomeNewV = csw.ltincome_from_utility(wk, workStartAge, ltUtilV,
            100.0, 10_000.0);
        @test isapprox(ltIncomeV, ltIncomeNewV, rtol = 0.001)
	end
end

@testset "Compensating variations" begin
    cv_test()
end


# --------