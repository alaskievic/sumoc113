using Pkg; pkgs = ["BenchmarkTools", "Enzyme", "ForwardDiff", "Plots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using ForwardDiff, Enzyme, Test
using BenchmarkTools
using Plots


### Simple Integral ###
# One dimensional
using Integrals
f(x, p) = sin(x * p)
p = 1.7
domain = (-2, 5) # (lb, ub)
prob = IntegralProblem(f, domain, p)
sol = Integrals.solve(prob, QuadGKJL()) # to avoid global variable conflict

# Multidimensional
using Integrals
f(x, p) = sum(sin.(x))       # note broadcast
domain = (ones(2), 3ones(2)) # (lb, ub)
prob = IntegralProblem(f, domain)
sol = Integrals.solve(prob, HCubatureJL(), reltol = 1e-3, abstol = 1e-3)

# Parallelize
using Integrals, Cubature, Base.Threads
function f(dx, x, p)
    Threads.@threads for i in 1:size(x, 2)
        dx[i] = sum(sin, @view(x[:, i]))
    end
end
domain = (ones(2), 3ones(2)) # (lb, ub)
prob = IntegralProblem(BatchIntegralFunction(f, zeros(0)), domain)
sol = solve(prob, CubatureJLh(), reltol = 1e-3, abstol = 1e-3)


### A simple differentiation ###
using ForwardDiff

function f(a, b; N = 50)
    r = range(a, b, length = N) # one
    return mean(r)
end

# d/db f(0.0, b) = 1/2
Df(x) = ForwardDiff.derivative(y -> f(0.0, y), x)

@show f(0.0, 3.0)
@show f(0.0, 3.1)
Df(3.0)

### Differentiable programming is the natural evolution of automatic differentiation ###
h(x) = sin(x[1]) + x[1] * x[2] + sinh(x[1] * x[2]) # multivariate
x = [1.4 2.2]
@show ForwardDiff.gradient(h, x) # use AD, seeds from x

#Or, can use complicated functions of many variables
f(x) = sum(sin, x) + prod(tan, x) * sum(sqrt, x)
g = (x) -> ForwardDiff.gradient(f, x); # g() is now the gradient
g(rand(5)) # gradient at a random point
# ForwardDiff.hessian(f,x') # or the hessian

# ForwardDiff.jl
function squareroot(x) #pretending we don't know sqrt()
    z = copy(x) # Initial starting point for Newton’s method
    while abs(z * z - x) > 1e-13
        z = z - (z * z - x) / (2z)
    end
    return z
end
squareroot(2.0)

dsqrt(x) = ForwardDiff.derivative(squareroot, x)
dsqrt(2.0)

# Reverse mode AD
# Unlike forward-mode auto-differentiation, 
# reverse-mode is very difficult to implement efficiently, 
# and many variations on the best approach exist

# Let's use Enzyme.jl
# A common pattern is f!(out, inputs..., params, cache) where 
# params holds model parameters (often as a named tuple) and 
# cache holds temporary work arrays passed last

rosenbrock(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
# Use Reverse-mode AD
x = [1.0, 2.0]
@show gradient(Reverse, rosenbrock, x)
# Return a tuple with the "primal" (i.e., function value) and grad
@show gradient(ReverseWithPrimal, rosenbrock, x);


f(x) = [(1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2;
        x[1] * x[2]]
@show jacobian(Forward, f, x)
@show jacobian(Reverse, f, x)
@show jacobian(ReverseWithPrimal, f, x);


using Enzyme, LinearAlgebra

f(x, y) = sum(x .* y)
x = [1.0, 2.0, 3.0]
y = [0.5, 1.0, 1.5]

# Forward mode: dx is the INPUT tangent (seed), derivative is RETURNED
# Seed with ones to get directional derivative in direction of all-ones
dx = ones(size(x))

# autodiff returns the derivative for scalar-valued functions
result = autodiff(Forward, f, Duplicated(x, dx), Const(y))

# result contains the directional derivative: ∂f/∂x · dx = sum(y .* dx) = 3.0
@show result

# Reverse mode
# Define function
calc(x, y) = sum(x .^ 2 .+ y)

x = [1.0, 2.0, 3.0]
y = [0.5, 0.5, 0.5]

# 1. Initialize Shadows with Zeros
dx = Enzyme.make_zero(x) # ∂f/∂x will accumulate here
dy = Enzyme.make_zero(y) # ∂f/∂y will accumulate here

# 2. Call autodiff
# In this case we find the gradient for all arguments
autodiff(Reverse, calc, Duplicated(x, dx), Duplicated(y, dy))

@show dx  # Should be 2*x -> [2.0, 4.0, 6.0]
@show dy;  # Should be 1.0 -> [1.0, 1.0, 1.0]

dx = Enzyme.make_zero(x)
dy = Enzyme.make_zero(y)
autodiff(ReverseWithPrimal, calc, Duplicated(x, dx), Duplicated(y, dy))



##### Quadrature and Interpolation #####
using Pkg; pkgs = ["Distributions", "FastGaussQuadrature", "Interpolations", "Plots", "QuadGK", "QuantEcon", "SpecialFunctions", "Integrals"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics, Distributions
using QuadGK, FastGaussQuadrature, SpecialFunctions
using Interpolations, Plots
using QuantEcon

# Now for integrals
using QuadGK
@show value, tol = quadgk(cos, -2π, 2π);


### Gauss Legendre ###
x, w = FastGaussQuadrature.gausslegendre(100_000); # i.e. find 100,000 nodes

# integrates f(x) = x^2 from -1 to 1
f(x) = x^2
@show dot(w, f.(x)); # calculate integral


# In economics we often wish to interpolate discrete data
# (i.e., build continuoususing Interpolations
using Interpolations
using Plots

x = -7:7            # x points, coase grid
y = sin.(x)         # corresponding y points

xf = -7:0.1:7       # fine grid
plot(xf, sin.(xf), label = "sin function")
scatter!(x, y, label = "sampled data", markersize = 4)

# Implementation
li = LinearInterpolation(x, y)
li_spline = CubicSplineInterpolation(x, y)

@show li(0.3) # evaluate at a single point

scatter(x, y, label = "sampled data", markersize = 4)
plot!(xf, li.(xf), label = "linear")
plot!(xf, li_spline.(xf), label = "spline")


li_spline = CubicSplineInterpolation(teste, y)
teste = -10:0.01:10
y = sin.(teste)         # corresponding y points
scatter(teste, y, label = "sampled data", markersize = 4)
plot!(teste, li_spline.(teste), label = "spline")


# Arbitrary irregular grid (no support for spline)
x = log.(range(1, exp(4), length = 10)) .+ 1  # uneven grid
y = log.(x) # corresponding y points

interp = LinearInterpolation(x, y)

xf = log.(range(1, exp(4), length = 100)) .+ 1 # finer grid

plot(xf, interp.(xf), label = "linear")
scatter!(x, y, label = "sampled data", markersize = 4, size = (800, 400))


### Multivariate Interpolation ###
f(x, y) = log(x + y)
xs = 1:0.2:5
ys = 2:0.1:5
A = [f(x, y) for x in xs, y in ys]

# linear interpolation
interp_linear = LinearInterpolation((xs, ys), A)
@show interp_linear(3, 2) # exactly log(3 + 2)
@show interp_linear(3.1, 2.1) # approximately log(3.1 + 2.1)

# cubic spline interpolation
interp_cubic = CubicSplineInterpolation((xs, ys), A)
@show interp_cubic(3, 2) # exactly log(3 + 2)
@show interp_cubic(3.1, 2.1) # approximately log(3.1 + 2.1);



### Discretization of Stochastic Processes ###

# Markov chains are routinely generated as discrete approximations to AR(1) processes

# Tauchen’s Method (1986)
function tauchen(N, rho, sigma, mu, m = 3)
    @assert abs(rho) < 1
    mu_X = mu / (1 - rho)
    sigma_X = sigma / sqrt(1 - rho^2)

    # zero-centered grid and midpoints as cutoffs
    z = range(-m*sigma_X, m*sigma_X, length = N)
    d = step(z)
    midpoints = (z[1:(end - 1)] .+ d/2)'
    means = rho .* z
    Z_scores = (midpoints .- means) ./ sigma

    # Construct P: [Left Tail, Interval Diffs, Right Tail]
    F = cdf.(Normal(), Z_scores)
    P = [F[:, 1] diff(F, dims = 2) (1 .- F[:, end])]
    x = z .+ mu_X
    return (; P, mu_X, sigma_X, x)
end

rho = 0.9
mu = 0.2
sigma = 0.1
N = 5
(; P, x) = tauchen(N, rho, sigma, mu)
@show x
println("Row sums of P: ", sum(P, dims = 2))

state_index = 3
println("Transition probabilities from state x = $(x[state_index]):")
for j in 1:N
    println("  to x = $(x[j]): P = $(P[state_index, j])")
end

N = 100
rho = 0.98
mu = 0.1
(; P, x) = tauchen(N, rho, sigma, mu)

heatmap(x, x, P,
        xlabel = "To State", ylabel = "From State",
        title = "Transition Matrix Heatmap", colorbar_title = "Probability")

threshold = 1E-6
num_nonzero = sum(P .> threshold)
println("Proportion of transitions > $threshold: ", num_nonzero / (N^2))



### Optimization and Nonlinear Solvers ###
using Pkg; pkgs = ["BenchmarkTools", "Enzyme", "FixedPointAcceleration", "ForwardDiff", "NLsolve", "NonlinearSolve", "Optim", "Optimization", "OptimizationOptimJL", "Roots", "StaticArrays", "JuMP"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics, BenchmarkTools
using ForwardDiff, Optim, Roots, NLsolve
using FixedPointAcceleration, NonlinearSolve
using Optimization, OptimizationOptimJL, ForwardDiff, Enzyme
using Optim: converged, maximum, maximizer, minimizer, iterations #some extra functions
using StaticArrays


### Optim.jl ###
# A good pure-Julia solution for the (unconstrained or box-bounded) optimization
# By default it targets minimization rather than maximization
using Optim: converged, maximum, maximizer, minimizer, iterations #some extra functions
result = optimize(x -> x^2, -2.0, 1.0)

### Unconstrained Multivariate Optimization ####
f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
x_iv = [0.0, 0.0]
results = optimize(f, x_iv) # i.e. optimize(f, x_iv, NelderMead())

results = optimize(f, x_iv, LBFGS())
println("minimum = $(results.minimum) with argmin = $(results.minimizer) in " *
        "$(results.iterations) iterations")


# sometimes we might be required to pass derivatives
f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
x_iv = [0.0, 0.0]
results = optimize(f, x_iv, LBFGS(), autodiff = :forward) # i.e. use ForwardDiff.jl
println("minimum = $(results.minimum) with argmin = $(results.minimizer) in " *
        "$(results.iterations) iterations")

# Analytical gradient
f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
x_iv = [0.0, 0.0]
function g!(G, x)
    G[1] = -2.0 * (1.0 - x[1]) - 400.0 * (x[2] - x[1]^2) * x[1]
    G[2] = 200.0 * (x[2] - x[1]^2)
end

results = optimize(f, g!, x_iv, LBFGS()) # or ConjugateGradient()
println("minimum = $(results.minimum) with argmin = $(results.minimizer) in " *
        "$(results.iterations) iterations")


f(x) = (1.0 - x[1])^2 + 100.0 * (x[2] - x[1]^2)^2
x_iv = [0.0, 0.0]
results = optimize(f, x_iv, SimulatedAnnealing()) # or ParticleSwarm() or NelderMead()


###  JuMP.jl ###
using JuMP, Ipopt
# solve
# max( x[1] + x[2] )
# st sqrt(x[1]^2 + x[2]^2) <= 1

function squareroot(x) # pretending we don't know sqrt()
    z = x # Initial starting point for Newton’s method
    while abs(z * z - x) > 1e-13
        z = z - (z * z - x) / (2z)
    end
    return z
end
m = Model(Ipopt.Optimizer)
# need to register user defined functions for AD
JuMP.register(m, :squareroot, 1, squareroot, autodiff = true)

@variable(m, x[1:2], start=0.5) # start is the initial condition
@objective(m, Max, sum(x))
@NLconstraint(m, squareroot(x[1]^2 + x[2]^2)<=1)
@show JuMP.optimize!(m)


# solve
# min (1-x)^2 + (100(y-x^2)^2)
# st x + y >= 10

using JuMP, Ipopt
m = Model(Ipopt.Optimizer) # settings for the solver
@variable(m, x, start=0.0)
@variable(m, y, start=0.0)

@NLobjective(m, Min, (1 - x)^2+100(y - x^2)^2)

JuMP.optimize!(m)
println("x = ", value(x), " y = ", value(y))

# adding a (linear) constraint
@constraint(m, x + y==10)
JuMP.optimize!(m)
println("x = ", value(x), " y = ", value(y))


### Nonlinear optimization ###
c = 2.0
f(u, p) = u .* u .- c # p ignored
u0 = [1.0, 1.0]
prob = NonlinearProblem(f, u0) # defaults to p = nothing
sol = solve(prob, NewtonRaphson())


### Small Systems ###
using StaticArrays
p = 2.0
f_SA(u, p) = SA[u[1] * u[1] - p, u[2] * u[2] - p] # rewrote without broadcasting
u0_static = SA[1.0, 1.0] # static array
prob = NonlinearProblem(f_SA, u0_static, p)


### Roots ###
using Roots
f(x) = sin(4 * (x - 1 / 4)) + x + x^20 - 1
fzero(f, 0, 1)








