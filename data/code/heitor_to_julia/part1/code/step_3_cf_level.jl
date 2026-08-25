using JLD2, Plots

# load data
@load "../output/calibration.jld2" calibration

d     = calibration["d"]
T     = calibration["T"]
N     = calibration["N"]
theta = calibration["theta"]
I_num = calibration["I"]

# ------------------------------------------------------------
# SIMULATE BASELINE
# ------------------------------------------------------------

# Initialize variables
# pick T
T_cases = hcat(T, T)
T_cases[1, 2] *= 1.2
w = ones(I_num)

E      = w .* N
pi_nom = T_cases[:, 1] .* (d .* w) .^ (-theta) # dim 1 origin, dim 2 destination
Phi    = sum(pi_nom, dims = 1)                 # sum over dim 1 - multilateral resistance
pi     = pi_nom ./ Phi
X      = pi .* transpose(E)

function counterfact_level(T_cases, theta, d, N;
                           tol_N = 1e-6,
                           max_count_N = 1000,
                           adj_exp_N = 0.5,
                           adj_sum_N = 0.5)

    w_cases = similar(T_cases)
    W_cases = similar(T_cases)
    w = ones(length(N))

    for tx in axes(T_cases, 2)
        T_current = T_cases[:, tx]

        dif_tol_N = 1.0
        count_N = 1

        Phi = nothing

        while dif_tol_N > tol_N && count_N < max_count_N
            w = w ./ w[1]
            E = w .* N

            pi_nom = T_current .* (d .* w) .^ (-theta)
            Phi = sum(pi_nom, dims = 1)
            pi = pi_nom ./ Phi

            X = pi .* transpose(E)

            N_dem = vec(sum(X, dims = 2)) ./ w
            dif_adj_N = N_dem ./ N
            dif_tol_N = maximum(abs.(1 .- dif_adj_N))

            w_new = w .* dif_adj_N .^ adj_exp_N
            w_new = w_new ./ w_new[1]

            w = w .* adj_sum_N .+ w_new .* (1 - adj_sum_N)

            count_N += 1
        end

        P_index = vec(Phi .^ (-1 / theta))

        w_cases[:, tx] = w
        W_cases[:, tx] = w ./ P_index
    end

    return (; w_cases, W_cases)
end

### Run function
results = counterfact_level(T_cases, theta, d, N)
w_cases = results.w_cases
W_cases = results.W_cases

# see relative wages
w_hat = w_cases[:, 2] ./ w_cases[1, 2]

# make figure
D_rincome = 100 .* (W_cases[:, 2] .- W_cases[:, 1]) ./ W_cases[:, 1]

# for visualization, remove the gains for country/location 1
D_rincome[1] = maximum(D_rincome[2:end])

I_side = round(Int, sqrt(I_num))
D_rincome_mat = reshape(D_rincome, I_side, I_side)

heatmap(D_rincome_mat, colorbar = true, yflip = true)
savefig("../output/map_D_real_income_levels.png")
