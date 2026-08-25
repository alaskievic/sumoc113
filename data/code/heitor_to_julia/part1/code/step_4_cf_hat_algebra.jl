using JLD2, Plots

# load data
@load "../output/data_square_world.jld2"

E_data = data["E"]
X_data = data["X"]
N      = data["N"]
I_num  = length(E_data)

# trade elasticity
theta = 4.0

# construct pi_0 matrix and E_0
pi_0 = X_data ./ sum(X_data, dims = 1)
E_0  = E_data

# counterfactual changes in exogenous parameters
T_hat = ones(I_num)
T_hat[1] = 1.2
d_hat = ones(size(X_data))

# initiate loop
w_hat = ones(I_num)

function counterfact_hat(theta, w_hat, T_hat, d_hat, E_0, pi_0; 
                        adj_exp = 0.5, adj_sum = 0.5,
                        dif_tol = 1.0, tol = 1e-6, 
                        max_count = 1000)
    # initialize loop
    count = 1                     
    while dif_tol > tol && count < max_count

        # ensure first country is numeraire
        w_hat = w_hat ./ w_hat[1]
        E_hat = w_hat

        # change in multilateral resistance term
        Phi_hat = sum(pi_0 .* T_hat .* (d_hat .* w_hat) .^ (-theta), dims = 1)

        # change in trade
        X_hat = ((T_hat .* (d_hat .* w_hat) .^ (-theta)) ./ Phi_hat) .* transpose(E_hat)

        # implied change in wages
        w_hat_new = vec(sum(pi_0 .* transpose(E_0) .* X_hat, dims = 2)) ./ E_0

        dif_adj = w_hat_new ./ w_hat
        dif_tol = maximum(abs.(1 .- dif_adj))

        w_hat_new = w_hat .* dif_adj .^ adj_exp
        w_hat_new = w_hat_new ./ w_hat_new[1]

        w_hat = w_hat_new .* adj_sum .+ w_hat .* (1 - adj_sum)

        count += 1
    end
    # recompute final objects using final w
    Phi_hat = sum(pi_0 .* T_hat .* (d_hat .* w_hat) .^ (-theta), dims = 1)
    return (; Phi_hat, w_hat)
end

# run functions
results = counterfact_hat(theta, w_hat, T_hat, d_hat, E_0, pi_0)
Phi_hat = results.Phi_hat
w_hat   = results.w_hat

# change in price index
Pindex_hat = vec(Phi_hat .^ (-1 / theta))
D_rincome = 100 .* (w_hat ./ Pindex_hat .- 1)

# make figure
D_rincome[1] = maximum(D_rincome[2:end])  # remove gains for location 1 visually

I_side = round(Int, sqrt(I_num))
D_rincome_mat = reshape(D_rincome, I_side, I_side)

heatmap(D_rincome_mat, colorbar = true, yflip = true)
savefig("../output/map_D_real_income_hat.png")
