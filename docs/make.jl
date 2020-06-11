using Documenter, CollegeStratWorker

makedocs(
    modules = [CollegeStratWorker],
    format = Documenter.HTML(; prettyurls = get(ENV, "CI", nothing) == "true"),
    authors = "hendri54",
    sitename = "CollegeStratWorker.jl",
    pages = Any["index.md"]
    # strict = true,
    # clean = true,
    # checkdocs = :exports,
)

# deploydocs(
#     repo = "github.com/hendri54/CollegeStratWorker.jl.git",
#     push_preview = true
# )
