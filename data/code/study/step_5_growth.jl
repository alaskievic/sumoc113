### Optimal Growth ###

# The Policy Function Approach
# A policy function is a map from past and present observables into current action
# Markov policies map current state into current action (state and control variables)

using Pkg; pkgs = ["Interpolations", "LaTeXStrings", "NLsolve", "Optim", "Plots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using LaTeXStrings, Interpolations, NLsolve, Optim, Random
using Optim: maximum, maximizer
using Plots


### First some approximations ###
f(x) = 2 .* cos.(6x) .+ sin.(14x) .+ 2.5
c_grid = 0:0.2:1
f_grid = range(0, 1, length = 150)
Af = LinearInterpolation(c_grid, f(c_grid))

plt = plot(xlim = (0, 1), ylim = (0, 6))
plot!(plt, f, f_grid, color = :blue, lw = 2, alpha = 0.8,
      label = "true function")
plot!(plt, f_grid, Af.(f_grid), color = :green, lw = 2, alpha = 0.8,
      label = "linear approximation")
plot!(plt, f, c_grid, seriestype = :sticks, linestyle = :dash, linewidth = 2,
      alpha = 0.5,
      label = "")
plot!(plt, legend = :top)

### The Bellman Operator ###
function T(w; p, tol = 1e-10)
    (; beta, u, f, Xi, y) = p # unpack parameters
    w_func = LinearInterpolation(y, w)

    Tw = similar(w)
    sigma = similar(w)
    for (i, y_val) in enumerate(y)
        # solve maximization for each point in y, using y itself as initial condition.
        results = maximize(c -> u(c; p) +
                                beta * mean(w_func.(f(y_val - c; p) .* Xi)), # Monte Carlo Integration Method
                           tol, y_val)
        Tw[i] = maximum(results)
        sigma[i] = maximizer(results)
    end
    return (; w = Tw, sigma) # returns named tuple of results
end

# Example time!!!!
Random.seed!(42)    # for reproducible results
u(c; p) = log(c)    # utility
f(k; p) = k^p.alpha # deterministic part of production function
function OptimalGrowthModel(; alpha = 0.4, beta = 0.96, mu = 0.0, s = 0.1,
                            u = u, f = f, # defaults defined above
                            y = range(1e-5, 4.0, length = 200), # grid on y
                            Xi = exp.(mu .+ s * randn(250)))
    return (; alpha, beta, mu, s, u, f, y, Xi)
end # named tuples defaults

# True value and policy function
function v_star(y; p)
    (; alpha, mu, beta) = p
    c1 = log(1 - alpha * beta) / (1 - beta)
    c2 = (mu + alpha * log(alpha * beta)) / (1 - alpha)
    c3 = 1 / (1 - beta)
    c4 = 1 / (1 - alpha * beta)
    return c1 + c2 * (c3 - c4) + c4 * log(y)
end
c_star(y; p) = (1 - p.alpha * p.beta) * y

p = OptimalGrowthModel()  # use all default parameters from named tuple
w_star = v_star.(p.y; p)  # evaluate closed form value along grid
w = T(w_star; p).w        # evaluate operator, access Tw results
w = 5 * log.(p.y)         # An initial condition -- fairly arbitrary
n = 35

plot(xlim = (extrema(p.y)), ylim = (-50, 10))
lb = "initial condition"
plt = plot(p.y, w, color = :black, linewidth = 2, alpha = 0.8, label = lb)
for i in 1:n
    w = T(w; p).w
    plot!(p.y, w, color = RGBA(i / n, 0, 1 - i / n, 0.8), linewidth = 2,
          alpha = 0.6,
          label = "")
end

lb = "true value function"
plot!(plt, p.y, v_star.(p.y; p), color = :black, linewidth = 2, alpha = 0.8,
      label = lb)
plot!(plt, legend = :bottomright)

# Fixed Point #
function solve_optgrowth(initial_w; p, iterations = 500, m = 3,
                         show_trace = false)
    results = fixedpoint(w -> T(w; p).w, initial_w; iterations, m, show_trace) # Anderson iteration
    v_star = results.zero
    sigma = T(results.zero; p).sigma
    return (; v_star, sigma, results)
end

initial_w = 5 * log.(p.y)
sol = solve_optgrowth(initial_w; p)
v_star_approx = sol.v_star
println("Converged in $(sol.results.iterations) to an ||residuals||_∞ of $(sol.results.residual_norm)")

plt = plot(ylim = (-35, -24))
plot!(plt, p.y, v_star_approx, linewidth = 2, alpha = 0.6,
      label = "approximate value function")
plot!(plt, p.y, v_star.(p.y; p), linewidth = 2, alpha = 0.6,
      label = "true value function")
plot!(plt, legend = :bottomright)


### Time Iteration ###

# The Coleman Operator #
# Solves the Euler Equation the same way the Bellman operator solvers the Bellman Equation
# First, on a theoretical level, the two methods are essentially isomorphic
# Numerical implementation is faster for Coleman

using Pkg; pkgs = ["BenchmarkTools", "Interpolations", "LaTeXStrings", "Optim", "Plots", "Roots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using BenchmarkTools, Interpolations, LaTeXStrings,  Plots, Roots
using Optim, Random
using BenchmarkTools, Interpolations, Plots, Roots

function K!(Kg, g, grid, beta, dudc, f, f_prime, shocks)
    # This function requires the container of the output value as argument Kg

    # Construct linear interpolation object
    g_func = LinearInterpolation(grid, g, extrapolation_bc = Line())

    # solve for updated consumption value
    for (i, y) in enumerate(grid)
        function h(c)
            vals = dudc.(g_func.(f(y - c) * shocks)) .* f_prime(y - c) .* shocks
            return dudc(c) - beta * mean(vals)
        end
        Kg[i] = find_zero(h, (1e-10, y - 1e-10))
    end
    return Kg
end

# The following function does NOT require the container of the output value as argument
function K(g, grid, beta, dudc, f, f_prime, shocks)
    K!(similar(g), g, grid, beta, dudc, f, f_prime, shocks)
end

using Optim

function T(w, grid, beta, u, f, shocks, Tw = similar(w);
           compute_policy = false)

    # apply linear interpolation to w
    w_func = LinearInterpolation(grid, w, extrapolation_bc = Line())

    if compute_policy
        sigma = similar(w)
    end

    # set Tw[i] = max_c { u(c) + beta E w(f(y  - c) z)}
    for (i, y) in enumerate(grid)
        objective(c) = u(c) + beta * mean(w_func.(f(y - c) .* shocks))
        res = maximize(objective, 1e-10, y)

        if compute_policy
            sigma[i] = Optim.maximizer(res)
        end
        Tw[i] = Optim.maximum(res)
    end

    if compute_policy
        return Tw, sigma
    else
        return Tw
    end
end


isoelastic(c, gamma) = isone(gamma) ? log(c) : (c^(1 - gamma) - 1) / (1 - gamma)
function Model(; alpha = 0.65,                         # Productivity parameter
               beta = 0.95,                            # Discount factor
               gamma = 1.0,                             # Risk aversion
               mu = 0.0,                             # First parameter in lognorm(mu, sigma)
               s = 0.1,                             # Second parameter in lognorm(mu, sigma)
               grid = range(1e-6, 4, length = 200), # Grid
               grid_min = 1e-6,                     # Smallest grid point
               grid_max = 4.0,                      # Largest grid point
               grid_size = 200,                     # Number of grid points
               u = (c, gamma = gamma) -> isoelastic(c, gamma),  # utility function
               dudc = c -> c^(-gamma),                  # u_prime
               f = k -> k^alpha,                        # production function
               f_prime = k -> alpha * k^(alpha - 1))
    return (; alpha, beta, gamma, mu, s, grid, grid_min, grid_max, grid_size, u,
            dudc, f, f_prime)
end

# Shocks for Montecarlo
using Random
Random.seed!(42) # for reproducible results

shock_size = 250 # number of shock draws in Monte Carlo integral
shocks = collect(exp.(m.mu .+ m.s * randn(shock_size))); # generate shocks



function verify_true_policy(m, shocks, c_star)
    # compute (Kc_star)
    (; grid, beta, dudc, f, f_prime) = m
    c_star_new = K(c_star, grid, beta, dudc, f, f_prime, shocks)

    # plot c_star and Kc_star
    plot(grid, c_star, label = L"optimal policy $c^*$")
    plot!(grid, c_star_new, label = L"Kc^*")
    plot!(legend = :topleft)
end

c_star = (1 - m.alpha * m.beta) * m.grid # true policy (c_star)
verify_true_policy(m, shocks, c_star)













