using JLD2, Plots

# load fundamentals
@load "../output/fundamental_for_simulation.jld2"

d     = fundamentals["d"]
I     = fundamentals["I"]
T     = fundamentals["T"]
N     = fundamentals["N"]
coord = fundamentals["coord"]

# Initialize variables
theta = 4.0
w = ones(I)

function solve_levels(theta, w, d, T, N, coord;
                      dif_tol = 1.0, tol = 1e-6, max_count = 1000,
                      adj_exp = 0.5, adj_sum = 0.5)

    count = 1

    while dif_tol > tol && count < max_count
        w = w ./ w[1]
        E = w .* N

        pi_nom = T .* (d .* w) .^ (-theta)
        Pi     = sum(pi_nom, dims = 1)
        pi     = pi_nom ./ Pi

        X = pi .* transpose(E)

        N_dem     = vec(sum(X, dims = 2)) ./ w
        dif_adj_N = N_dem ./ N
        dif_tol_N = maximum(abs.(1 .- dif_adj_N))

        w_new = w .* dif_adj_N .^ adj_exp
        w_new = w_new ./ w_new[1]

        w = w .* adj_sum .+ w_new .* (1 - adj_sum)

        dif_tol = dif_tol_N
        count += 1

        println("Tolerance in N = ", dif_tol_N)
        println("Iteration = ", count)
    end

    # recompute final objects using final w
    w = w ./ w[1]
    E = w .* N

    pi_nom = T .* (d .* w) .^ (-theta)
    Pi     = sum(pi_nom, dims = 1)
    pi     = pi_nom ./ Pi
    X      = pi .* transpose(E)

    return Dict(
        "E" => E,
        "X" => X,
        "N" => N,
        "Pi" => Pi,
        "w" => w,
        "coord" => coord
    )
end

# Run the function
data = solve_levels(theta, w, d, T, N, coord)
data["X"]

@save "../output/data_square_world.jld2" data

# make real income figure
Pi     = data["Pi"]
w      = data["w"]
Pindex = vec(Pi .^ (-(1 / theta)))
rincome = w ./ Pindex

I_side = round(Int, sqrt(I))
rincome_mat = reshape(rincome, I_side, I_side)

heatmap(rincome_mat, colorbar = true, yflip = true)
savefig("../output/map_real_income.png")

# make tfp figure
T_mat = reshape(T, I_side, I_side)

heatmap(T_mat, colorbar = true, yflip = true)
savefig("../output/map_tfp.png")






