# CollegeStratWorker

This package contains the worker problem for the `CollegeStrat` model.

This currently solves the simplest permanent income problem.

## Worker Utility

```@docs
WorkerUtility
```

## Worker

Solving the worker problem really just means computing [`lifetime_utility`](@ref).

[`lifetime_utility_function`](@ref) generates a spline approximation of lifetime utility on grids of asset and human capital values. This can be used to represent the value of working for given education and work start age.

For experiments, we want to know how much a student would be willing to pay for certain changes (e.g., admission to a better college). For this purpose, [`ltincome_from_utility`](@ref) computes the lifetime income that allows a worker to achieve a fixed lifetime utility. The idea is to convert all utilities into lifetime incomes for high school graduate workers and to compute compensating differentials based on those.

```@docs
Worker
exper_profile
log_exper_profile
lifetime_earnings
lifetime_utility
lifetime_utility_vector
lifetime_utility_grid
lifetime_utility_function
mu_wealth
cons_age1
ltincome_from_utility
```

## WorkHistories

```@docs
WorkHistories
simulate_workers!
simulate_one_worker!
```

--------------