using JLD2, LinearAlgebra

# load data
@load "../output/data_square_world.jld2" data

E_data = data["E"]
X_data = data["X"]
N      = data["N"]

# ------------------------------------------------------------
# RECOVER TRADE COSTS
# ------------------------------------------------------------

I_num = length(E_data)

FE_o = kron(Matrix{Float64}(LinearAlgebra.I, I_num, I_num), ones(I_num, 1))
FE_d = kron(ones(I_num, 1), Matrix{Float64}(LinearAlgebra.I, I_num, I_num))

y_var = log.(vec(X_data))
X_var = hcat(FE_o, FE_d)

beta = pinv(X_var' * X_var) * (X_var' * y_var)
res  = y_var .- X_var * beta

theta = 4.0

tcost     = exp.(res) .^ (-(1 / theta))
tcost_mat = reshape(tcost, I_num, I_num)
d         = tcost_mat ./ diag(tcost_mat)

# ------------------------------------------------------------
# RECOVER TFPS
# ------------------------------------------------------------

E_target = E_data ./ E_data[1]
T = ones(I_num)
w = ones(I_num)

function calibrate_model(theta, T, w, d, N, E_target;
                         adj_exp_N = 0.5, adj_sum_N = 0.5,
                         adj_exp_T = 0.5, adj_sum_T = 0.5,
                         dif_tol_T = 1.0, tol_T = 1e-6,
                         max_count_T = 1000,
                         tol_N = 1e-6, max_count_N = 1000)

    I_num = length(N)
    count_T = 1

    X = zeros(I_num, I_num)

    while dif_tol_T > tol_T && count_T < max_count_T

        dif_tol_N = 1.0
        count_N = 1

        while dif_tol_N > tol_N && count_N < max_count_N

            # income
            w = w ./ w[1]
            E = w .* N

            # expenditure shares
            pi_nom = T .* (d .* w) .^ (-theta)
            Pi     = sum(pi_nom, dims = 1)
            pi     = pi_nom ./ Pi

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

        # compare model-implied with actual gross output
        E_model = vec(sum(X, dims = 2))
        E_model = E_model ./ E_model[1]

        dif_adj_T = E_target ./ E_model
        dif_tol_T = maximum(abs.(1 .- dif_adj_T))

        T_new = T .* dif_adj_T .^ adj_exp_T
        T_new = T_new ./ T_new[1]

        T = T .* adj_sum_T .+ T_new .* (1 - adj_sum_T)
        T = T ./ T[1]

        println("Tolerance in N (inner) = ", dif_tol_N)
        println("Tolerance in T (outer) = ", dif_tol_T)
        println("count (outer) = ", count_T)

        count_T += 1
    end

    # recompute final objects using final T and w
    w = w ./ w[1]
    E = w .* N

    pi_nom = T .* (d .* w) .^ (-theta)
    Pi     = sum(pi_nom, dims = 1)
    pi     = pi_nom ./ Pi
    X      = pi .* transpose(E)

    return Dict(
        "d" => d,
        "T" => T,
        "N" => N,
        "theta" => theta,
        "I" => I_num,
        "w" => w,
        "E" => E,
        "X" => X,
        "Pi" => Pi
    )
end

calibration = calibrate_model(theta, T, w, d, N, E_target)

@save "../output/calibration.jld2" calibration

X = calibration["X"]

# ------------------------------------------------------------
# CHECK RESULTS
# ------------------------------------------------------------

# trade flows should be rationalized
X_check = X ./ X_data

# compare with original fundamentals
@load "../output/fundamental_for_simulation.jld2"

T_fund = fundamentals["T"]
d_fund = fundamentals["d"]

T_check = T ./ T_fund
d_check = d ./ d_fund