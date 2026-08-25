using JLD2, Plots

# load data
@load "../output/calibration.jld2" calibration

d     = calibration["d"]
T     = calibration["T"]
N     = calibration["N"]
theta = calibration["theta"]
I_num = calibration["I"]

function counterfact_welfare(d, T, N, theta;
                             adj_exp_N = 0.5,
                             adj_sum_N = 0.5,
                             tol_N = 1e-6,
                             max_count_N = 1000)

    I_num = length(N)

    # two T cases: baseline and T[1] increased by 20 percent
    T_cases = hcat(T, T)
    T_cases[1, 2] *= 1.2

    W_cases  = zeros(size(T_cases))
    w_cases  = zeros(size(T_cases))
    pi_cases = zeros(size(T_cases))

    w = ones(I_num)

    for tx in axes(T_cases, 2)

        T_current = T_cases[:, tx]

        dif_tol_N = 1.0
        count_N   = 1

        Phi = nothing
        X   = nothing

        while dif_tol_N > tol_N && count_N < max_count_N

            # income
            w = w ./ w[1]
            E = w .* N

            # expenditure shares
            pi_nom = T_current .* (d .* w) .^ (-theta)
            Phi    = sum(pi_nom, dims = 1)
            pi     = pi_nom ./ Phi

            # total sales
            X = pi .* transpose(E)

            # demand for labor
            N_dem     = vec(sum(X, dims = 2)) ./ w
            dif_adj_N = N_dem ./ N
            dif_tol_N = maximum(abs.(1 .- dif_adj_N))

            w_new = w .* dif_adj_N .^ adj_exp_N
            w_new = w_new ./ w_new[1]

            w = w .* adj_sum_N .+ w_new .* (1 - adj_sum_N)

            count_N += 1
        end

        P_index = vec(Phi .^ (-1 / theta))

        w_cases[:, tx]  = w
        W_cases[:, tx]  = w ./ P_index
        pi_cases[:, tx] = diag(X) ./ vec(sum(X, dims = 1))
    end

    w_hat = w_cases[:, 2] ./ w_cases[1, 1]

    D_rincome = 100 .* (W_cases[:, 2] .- W_cases[:, 1]) ./ W_cases[:, 1]

    D_rincome_gft =
        100 .* (
            (pi_cases[:, 2] ./ pi_cases[:, 1]) .^ (-1 / theta) .*
            (1 ./ (T_cases[:, 2] ./ T_cases[:, 1]) .^ (-1 / theta)) .-
            1
        )

    return Dict(
        "T_cases" => T_cases,
        "W_cases" => W_cases,
        "w_cases" => w_cases,
        "pi_cases" => pi_cases,
        "w_hat" => w_hat,
        "D_rincome" => D_rincome,
        "D_rincome_gft" => D_rincome_gft

        
    )
end

results = counterfact_welfare(d, T, N, theta)

scatter(
    log.(results["D_rincome"]),
    log.(results["D_rincome_gft"]),
    xlabel = "log(D_rincome)",
    ylabel = "log(D_rincome_gft)",
    legend = false
)

savefig("../output/scatter_real_income_gft.png")
