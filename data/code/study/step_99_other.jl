### My Own Monte Carlo Integration Example ###
using Pkg; pkgs = ["Distributions"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using Distributions, Random

throws = 10^7
radius = 1

# Choose random X and Y data centered around 0,0
dist =  Uniform(-radius, radius)
x = rand(dist, throws)
y = rand(dist, throws)

# Count the times (x, y) is inside the circle,
# which happens when sqrt(x^2 + y^2) <= radius.
inside_circle = count(hypot.(x, y) .<= radius)

# Calculate area and print; should be closer to Pi with increasing number of throws
area = (2 * radius)^2 * inside_circle / throws


Random.seed!(42)    # for reproducible results
# A function #
function Monte(throws; radius = 1)
    dist =  Uniform(-radius, radius)
    x = rand(dist, throws)
    y = rand(dist, throws)
    inside_circle = count(hypot.(x, y) .<= radius)

    # Calculate area and print; should be closer to Pi with increasing number of throws
    area = (2 * radius)^2 * inside_circle / throws
    return(area)
end

throws = 10 .^ (1:8)

for throw in throws
    println("throws = $throw, estimated area = $(Monte(throw))")
end

### More speed ###
using Random
using Base.Threads

function Monte_threaded(throws; radius = 1.0)
    counts = zeros(Int, nthreads())
    r2 = radius^2

    @threads for _ in 1:throws
        x = (2rand() - 1) * radius
        y = (2rand() - 1) * radius

        if x^2 + y^2 <= r2
            counts[threadid()] += 1
        end
    end

    inside = sum(counts)
    return (2radius)^2 * inside / throws
end

throws = 10 .^ (1:9)
for throw in throws
    println("throws = $throw, estimated area = $(Monte(throw))")
end


### Monte Carlo Markov Chain (MCMC) and Metropolis-Hastings ###
using Random
using Distributions

# Sample from a standard Normal
target_distribution(x) = pdf(Normal(0, 1), x)

# Metropolis-Hastings #
function metropolis_hastings(target_distribution, initial_value, num_samples, proposal_std)
    samples = Vector{Float64}(undef, num_samples)
    current_sample = initial_value
    
    for i in 1:num_samples
        proposal = current_sample + rand(Normal(0, proposal_std))
        acceptance_ratio = target_distribution(proposal) / target_distribution(current_sample)
        
        if rand() < acceptance_ratio
            current_sample = proposal
        end
        
        samples[i] = current_sample
    end
    
    return samples
end

initial_value = 0.0
num_samples = 10000
proposal_std = 1.0

samples = metropolis_hastings(target_distribution, initial_value, num_samples, proposal_std)

# Visualize #
using Plots
histogram(samples, normalize = true, label = "MCMC Samples")
x = -4:0.1:4
plot!(x, pdf.(Normal(0, 1), x), label = "Target Distribution", linewidth = 2)



# Another examples #
using Random
using Distributions

function metropolis_hastings(target_log_pdf, initial_val, num_samples, proposal_std)
    # Pre-allocate array with explicit Float64 types for speed
    samples = Vector{Float64}(undef, num_samples)
    current_val = initial_val
    current_log_p = target_log_pdf(current_val)
    
    accepted = 0

    for i in 1:num_samples
        # Propose a candidate value: X' ~ N(X_current, proposal_std)
        candidate = current_val + proposal_std * randn()
        candidate_log_p = target_log_pdf(candidate)
        
        # Calculate acceptance probability in log-space to prevent underflow
        log_alpha = candidate_log_p - current_log_p
        
        # Accept or reject
        if log(rand()) < log_alpha
            current_val = candidate
            current_log_p = candidate_log_p
            accepted += 1
        end
        
        samples[i] = current_val
    end
    
    @info "Empirical Acceptance Rate: $(accepted / num_samples * 100)%"
    return samples
end

# --- Execution ---
# Define log target distribution: Normal(0, 1)
log_target(x) = logpdf(Normal(0, 1), x)

# Generate 50,000 samples
chain = metropolis_hastings(log_target, 0.0, 50_000, 0.5)