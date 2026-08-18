### Differentiating Models of Economic Dynamics ###

# Use Enzyme.jl to differentiate simulations end-to-end #
using Pkg; pkgs = ["BenchmarkTools", "Enzyme", "EnzymeTestUtils", "Optimization", "OptimizationOptimJL", "Plots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Random, Test, Enzyme, Statistics
using Optimization, OptimizationOptimJL, EnzymeTestUtils
using BenchmarkTools
using Plots


function simulate_lss!(x, y, model, x_0, w, v)
    (; A, C, G, H) = model
    N, T1 = size(x)
    M, T1y = size(y)
    T = size(w, 2)

    @assert T1 == T + 1 == T1y
    @assert size(v, 2) == T + 1
    @assert size(A) == (N, N)
    @assert size(G) == (M, N)
    @assert size(C, 1) == N
    @assert size(H, 1) == M
    @assert length(x_0) == N

    # Enzyme has challenges with activity analysis on copyto!/broadcasting assignments
    @inbounds for i in 1:N
        x[i, 1] = x_0[i]
    end
    # Apply evolution and observation equations
    @inbounds for t in 1:T
        @views mul!(x[:, t + 1], A, x[:, t])             # x_{t+1} = A x_t
        @views mul!(x[:, t + 1], C, w[:, t], 1.0, 1.0)   # + C w_{t+1}

        @views mul!(y[:, t], G, x[:, t])                 # y_t = G x_t
        @views mul!(y[:, t], H, v[:, t], 1.0, 1.0)       # + H v_t
    end
    # Apply observation equation at T+1
    @views mul!(y[:, T + 1], G, x[:, T + 1])
    @views mul!(y[:, T + 1], H, v[:, T + 1], 1.0, 1.0)

    return nothing
end



Random.seed!(1234)
N, M, K, L = 3, 2, 2, 2
T = 10

A = [0.8 0.1 0.0
     0.0 0.7 0.1
     0.0 0.0 0.6]
C = 0.1 .* randn(N, K)
G = [1.0 0.0 0.0
     0.0 1.0 0.3]
H = 0.05 .* randn(M, L)
model = (; A, C, G, H)

x_0 = randn(N)
w = randn(K, T)
v = randn(L, T + 1)

x = zeros(N, T + 1)
y = zeros(M, T + 1)

simulate_lss!(x, y, model, x_0, w, v)

time = 0:T
plot(time, x', lw = 2, xlabel = "t", ylabel = "state", label = ["x1" "x2" "x3"],
     title = "State Paths")


plot(time, y', lw = 2, xlabel = "t", ylabel = "observation",
     label = ["y1" "y2"], title = "Observation Paths")


# forward-mode on w[1]
x = zeros(N, T + 1)
y = zeros(M, T + 1)
dx = Enzyme.make_zero(x)
dx_0 = Enzyme.make_zero(x_0)
dy = Enzyme.make_zero(y)
dw = Enzyme.make_zero(w)
dw[1] = 1.0                         # unit perturbation to first shock

autodiff(Forward,
         simulate_lss!,
         Duplicated(x, dx),
         Duplicated(y, dy),
         Const(model), # leaving model fixed
         Duplicated(x_0, dx_0), # won't perturb
         Duplicated(w, dw), # perturbing w
         Const(v))

dx[:, 1:3]   # early-state sensitivities (impulse response flavor)


dx_batch = (Enzyme.make_zero(x), Enzyme.make_zero(x))
dy_batch = (Enzyme.make_zero(y), Enzyme.make_zero(y))
dmodels = (Enzyme.make_zero(model), Enzyme.make_zero(model))
dmodels[1].A[1] = 1.0
dmodels[2].A[2] = 1.0

autodiff(Forward,
         simulate_lss!,
         BatchDuplicated(x, dx_batch), # batch duplicated to match dmodels
         BatchDuplicated(y, dy_batch),
         BatchDuplicated(model, dmodels),
         Const(x_0),
         Const(w),
         Const(v))
@show dy_batch[1], dy_batch[2];



### CALIBRATION !!! ###
function simulate_lss!(x, y, A, C, G, H, x_0, w, v)
    N, T1 = size(x)
    M, T1y = size(y)
    T = size(w, 2)

    @assert T1 == T + 1 == T1y
    @assert size(v, 2) == T + 1
    @assert size(A) == (N, N)
    @assert size(G) == (M, N)
    @assert size(C, 1) == N
    @assert size(H, 1) == M
    @assert length(x_0) == N

    # Enzyme has challenges with activity analysis on broadcasting assignments
    @inbounds for i in 1:N
        x[i, 1] = x_0[i]
    end
    # Apply evolution and observation equations
    @inbounds for t in 1:T
        @views mul!(x[:, t + 1], A, x[:, t])             # x_{t+1} = A x_t
        @views mul!(x[:, t + 1], C, w[:, t], 1.0, 1.0)   # + C w_{t+1}

        @views mul!(y[:, t], G, x[:, t])                 # y_t = G x_t
        @views mul!(y[:, t], H, v[:, t], 1.0, 1.0)       # + H v_t
    end
    # Apply observation equation at T+1
    @views mul!(y[:, T + 1], G, x[:, T + 1])
    @views mul!(y[:, T + 1], H, v[:, T + 1], 1.0, 1.0)

    return nothing
end

function parameterized_A(a)
    return [a 0.1 0.0; 0.0 0.7 0.1; 0.0 0.0 0.6]
end

function loss(u, p)
    (; x_0, w, v, y_target, C, G, H) = p
    T = size(w, 2)
    a = u[1]

    A = parameterized_A(a)

    # Allocate buffers and simulate
    x = zeros(eltype(A), length(x_0), T + 1)
    y = zeros(eltype(A), size(G, 1), T + 1)
    simulate_lss!(x, y, A, C, G, H, x_0, w, v)

    y_mean = mean_first_observation(y)
    return (y_mean - y_target)^2
end

y_target = 0.0 # target match

# Bundle parameters into a named tuple
p = (; x_0, w, v, y_target, C, G, H)

# Initial Guess for 'a'
u_0 = [0.8]

println("Initial a=$(u_0[1]), Loss: $(loss(u_0, p))")

# Define the problem type, associate initial condition and parameters
# AutoEnzyme() will handle the AD setup
optf = OptimizationFunction(loss, AutoEnzyme())
prob = OptimizationProblem(optf, u_0, p)

sol = solve(prob, OptimizationOptimJL.LBFGS())
println("Final a=$(sol.u[1]), Loss: $(loss(sol.u, p))")






