using Pkg; pkgs = ["Distributions", "LaTeXStrings", "StatsPlots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using LaTeXStrings, Distributions, Random, Statistics
using StatsPlots


function binomial_pdf(n)
    bar(0:n, pdf.(Binomial(n), 0:n),
        xticks = 0:10, ylim = (0, 1), yticks = 0:0.1:1,
        label = L"Binomial(%$n, 0.5)", legend = :topleft)
end

plot(binomial_pdf.((1, 2, 4, 8))...)

using StatsPlots

function simulation1(distribution, n = 250, k = 10_000)
    sigma = std(distribution)
    y = rand(distribution, n, k)
    y .-= mean(distribution)
    y = mean(y, dims = 1)
    y = √n * vec(y)
    density(y, label = "Empirical Distribution")
    return plot!(Normal(0, sigma), linestyle = :dash, color = :black,
                 label = L"Normal(0.00, %$(sigma^2))")
end
simulation1(Exponential(0.5))


function simulation2(distribution = Beta(2, 2), n = 5, k = 10_000)
    y = rand(distribution, k, n)
    for col in 1:n
        y[:, col] += rand([-0.5, 0.6, -1.1], k)
    end
    y = (y .- mean(distribution)) ./ std(distribution)
    y = cumsum(y, dims = 2) ./ sqrt.(1:5)' # return grid of data
end
ys = simulation2()
plots = [] # would preallocate in optimized code
for i in 1:size(ys, 2)
    p = density(ys[:, i], linealpha = i, title = L"n = %$i")
    push!(plots, p)
end

plot(plots..., legend = false, size = (900, 500))

