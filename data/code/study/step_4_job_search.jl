### Algorithm ###
# 1. pick an arbitrary initial guess 
# 2. compute a new vector v' with the recursion system of equations
# 3. calcualte a measure of the deviation between v and v'
# 4. if the deviation is larger than some fixed tolerance set v = v' and return to step 2, else continue
# 5. return v


using Pkg; pkgs = ["Distributions", "LaTeXStrings", "NLsolve", "Roots", "StatsPlots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using Distributions, LaTeXStrings
using NLsolve, Roots, Random
using StatsPlots

n = 50
dist = BetaBinomial(n, 200, 100) # probability distribution
@show support(dist)
p = pdf.(dist, support(dist))
w = range(10.0, 60.0, length = n + 1) # linearly space wages

using StatsPlots
plt = plot(w, p, xlabel = "wages", ylabel = "probabilities", legend = false)

# exploring expectations via direct dot products
wage(i) = w[i + 1] # +1 to map from support of 0
w = wage.(support(dist))
E_w = dot(p, w)
E_w_2 = dot(p, w .^ 2) - E_w^2 # variance
@show E_w, E_w_2

# could also use sum with elementwise product
@show sum(p .* w);

### parameters and constant objects ###
c = 25
beta = 0.99
num_plots = 6
n = 50
dist = BetaBinomial(n, 200, 100) # probability distribution
@show support(dist)
p = pdf.(dist, support(dist))
w = range(10.0, 60.0, length = n + 1) # linearly space wages

# Operator
# Broadcasts over the w, fixes the v
T(v) = max.(w / (1 - beta), c + beta * dot(v, p))
# alternatively, T(v) = [max(w_val/(1 - beta), c + beta * dot(v, p)) for w_val in w]

# fill in  matrix of vs
vs = zeros(n + 1, 6) # data to fill
vs[:, 1] .= w / (1 - beta) # initial guess of "accept all"
vs

# manually applying operator
for col in 2:num_plots
    v_last = vs[:, col - 1]
    vs[:, col] .= T(v_last)  # apply operator
end
vs
plot(vs)



# Brute force
function compute_reservation_wage_direct(params; v_iv = collect(w ./ (1 - beta)), max_iter = 500, tol = 1e-6)
    (; c, beta, w) = params

    # create a closure for the T operator
    T(v) = max.(w / (1 - beta), c + beta * dot(v, p)) # fixing the parameter values

    v = copy(v_iv)                                    # copy to prevent v_iv modification - IMPORTANT!!
    v_next = similar(v)
    i = 0
    error = Inf
    while i < max_iter && error > tol
        v_next .= T(v)
        error = norm(v_next - v)
        i += 1
        v .= v_next  # copy contents into v
    end
    # now compute the reservation wage
    return (1 - beta) * (c + beta * dot(v, p))
end


# If we had gone v = v_iv instead, then it would have simply created a new name v which binds to whatever is located at v_iv
# Since we later use v .= v_next later in the algorithm, the values in it would be modified
# Hence, we would be modifying the v_iv vector we were passed in, which may not be what the caller of the function wanted

# Let's find the fixed point of the T operator!!!
function compute_reservation_wage(params; v_iv = collect(w ./ (1 - beta)), iterations = 500, ftol = 1e-6, m = 1)
    (; c, beta, w) = params
    T(v) = max.(w / (1 - beta), c + beta * dot(v, p)) # fixing the parameter values

    sol = fixedpoint(T, v_iv; iterations, ftol, m)
    sol.f_converged || error("Failed to converge")
    v_star = sol.zero
    return (1 - beta) * (c + beta * dot(v_star, p))
end

function mcall_model(; c = 25.0, beta = 0.99, w = range(10.0, 60.0, length = n + 1))
    (; c, beta, w)
end

compute_reservation_wage(mcall_model()) # call with default parameters



### Comparative Statics ###
# Now we know how to compute the reservation wage, let’s see how it varies with parameters
grid_size = 25
R = zeros(grid_size, grid_size)

c_vals = range(10.0, 30.0, length = grid_size)
beta_vals = range(0.9, 0.99, length = grid_size)

for (i, c) in enumerate(c_vals)
    for (j, beta) in enumerate(beta_vals)
        R[i, j] = compute_reservation_wage(mcall_model(; c, beta); m = 0)
    end
end

contour(c_vals, beta_vals, R',
        title = "Reservation Wage",
        xlabel = L"c",
        ylabel = L"\beta",
        fill = true)

### Nonlinear solver based on the value of not accepting a job

# 1. pick an initial guess ψ
# 2. compute the update ψ': ψ' = c + β \sum_{i=1}^{n} max {w_{i}/1 - β, ψ}p_{i}
# 3. calculate the deviation
# 4. If deviation is larger set ψ = ψ' and go to step 2
# 5. return ψ 

# notice that this is a single number now (not a n-vector anymore)
function compute_reservation_wage_psi(c, beta; psi_iv = dot(w, p) / (1 - beta), iterations = 500, ftol = 1e-5, m = 1)
    T_psi(psi) = [c + beta * dot(max.((w ./ (1 - beta)), psi[1]), p)]
    # using vectors since fixedpoint doesn't support scalar
    sol = fixedpoint(T_psi, [psi_iv]; iterations, ftol, m)
    sol.f_converged || error("Failed to converge")
    psi_star = sol.zero[1]
    return (1 - beta) * psi_star
end
compute_reservation_wage_psi(c, beta)


# or solve for the root
function compute_reservation_wage_psi2(c, beta; psi_iv = dot(w, p) / (1 - beta),
                                       maxiters = 500, rtol = 1e-5)
    root_psi(psi) = c + beta * dot(max.((w ./ (1 - beta)), psi), p) - psi # (7)
    psi_star = find_zero(root_psi, psi_iv; maxiters, rtol)
    return (1 - beta) * psi_star # (2)
end
compute_reservation_wage_psi2(c, beta)


### Stopping Time ###
function compute_stopping_time(w_bar; seed = 1234)
    Random.seed!(seed)
    stopping_time = 0
    t = 1
    # make sure the constraint is sometimes binding
    @assert length(w) - 1 ∈ support(dist) && w_bar <= w[end]
    while true
        # Generate a wage draw
        w_val = w[rand(dist)] # the wage dist set up earlier
        if w_val >= w_bar
            stopping_time = t
            break
        else
            t += 1
        end
    end
    return stopping_time
end

function compute_mean_stopping_time(w_bar, num_reps = 10000)
    mean(i -> compute_stopping_time(w_bar,
                                    seed = i), 1:num_reps)
end
c_vals = range(10, 40, length = 25)
stop_times = similar(c_vals)

beta = 0.99
for (i, c) in enumerate(c_vals)
    w_bar = compute_reservation_wage_psi(c, beta)
    stop_times[i] = compute_mean_stopping_time(w_bar)
end

plot(c_vals, stop_times, label = "mean unemployment duration", xlabel = "unemployment compensation", ylabel = "months")


##### Search and Separation #####
using Pkg; pkgs = ["Distributions", "LaTeXStrings", "NLsolve", "Plots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using Distributions, LaTeXStrings, NLsolve, Plots

function solve_mccall_model(mcm; U_iv = 1.0, V_iv = ones(length(mcm.w)), tol = 1e-5, iter = 2_000)
    (; alpha, beta, sigma, c, gamma, w, dist, u, p) = mcm

    # parameter validation
    @assert c > 0.0
    @assert minimum(w) > 0.0 # perhaps not strictly necessary, but useful here

    # necessary objects
    u_w = mcm.u.(w, sigma)
    u_c = mcm.u(c, sigma)

    # Bellman operator T. Fixed point is x* s.t. T(x*) = x*
    function T(x)
        V = x[1:(end - 1)]
        U = x[end]
        V_p = u_w + beta * ((1 - alpha) * V .+ alpha * U)
        U_p = u_c + beta * (1 - gamma) * U + beta * gamma * sum(max(U, V[i]) * p[i] for i in 1:length(w))
        return [V_p; U_p]
    end

    # value function iteration
    x_iv = [V_iv; U_iv] # initial x val
    xstar = fixedpoint(T, x_iv, iterations = iter, xtol = tol, m = 0).zero
    V = xstar[1:(end - 1)]
    U = xstar[end]

    # compute the reservation wage
    wbarindex = searchsortedfirst(V .- U, 0.0)
    if wbarindex >= length(w) # if this is true, you never want to accept
        w_bar = Inf
    else
        w_bar = w[wbarindex] # otherwise, return the number
    end

    # return a NamedTuple, so we can select values by name
    return (; V, U, w_bar)
end

function mcall_model(; alpha = 0.2,
                     beta = 0.98, # discount rate
                     gamma = 0.7,
                     c = 6.0, # unemployment compensation
                     sigma = 2.0,
                     u = (c, sigma) -> (c^(1 - sigma) - 1) / (1 - sigma),
                     w = range(10, 20, length = 60), # wage values
                     dist = BetaBinomial(59, 600, 400)) # distribution over wage values
    p = pdf.(dist, support(dist))
    return (; alpha, beta, gamma, c, sigma, u, w, dist, p)
end

# plots setting
mcm = mcall_model()
(; V, U) = solve_mccall_model(mcm)
U_vec = fill(U, length(mcm.w))
plot(mcm.w, [V U_vec], lw = 2, alpha = 0.7, label = [L"V" L"U"])


### Search with Learning ###











