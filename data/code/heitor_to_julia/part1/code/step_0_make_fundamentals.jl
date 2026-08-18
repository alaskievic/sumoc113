### GEOGRAPHY ###
using JLD2

# Basic characteristics
I_side = 10                         # number of countries in each side of the square
I = I_side * I_side                 # total number of countries
coord = zeros(I, 2)                 # coordinates
matrix_ref = zeros(I_side, I_side)  # reference matrix
N = ones(I)                         # population

# Make TFPs
for i in 1:I_side
    for j in 1:I_side
        matrix_ref[i, j] = abs(i - 1) + abs(j - 1) + 1
    end
end

matrix_ref
T_sq = matrix_ref .^ (-0.1)         # TFP of countries in a square
T = vec(T_sq)                       # TFP of countries in a vector

# Make coordinates
row = 1                  # initialize       
for i in 1:I_side
    for j in 1:I_side
        coord[row, 1] = i
        coord[row, 2] = j
        row += 1
    end
end
coord

# Make iceberg trade cost
dist = zeros(I, I)

for i in 1:I
    for j in 1:I
        dist[i, j] = sqrt(sum((coord[i, :] .- coord[j, :]).^2))
    end
end

d0 = 0.01
d1 = 0.5
d = exp.(d0 .* dist .^ d1)

# Export data
fundamentals = Dict(
    "I" => I,
    "d" => d,
    "T" => T,
    "N" => N,
    "coord" => coord
)

mkpath("../output")
@save "../output/fundamental_for_simulation.jld2" fundamentals



matwrite("../output/fundamental_for_simulation.mat", Dict(
    "fundamentals" => fundamentals
))














