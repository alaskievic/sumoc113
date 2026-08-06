# install the packages
using Pkg; pkgs = ["Distributions", "ForwardDiff", "LaTeXStrings", "NLsolve", "Plots", "StaticArrays"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics, Plots, LaTeXStrings
using Distributions, ForwardDiff, NLsolve, StaticArrays

# random number generator - returns a a column vector n random draws from a normal distribution with mean 0 and variance 1
randn()

n = 100
ep = randn(n)
plot(1:n, ep)

# Arrays
typeof(ep) # Vector{Float64}

ep[1:5]

# In Julia, one-dimensional arrays are interpreted as column vectors for purposes of linear algebra

# For-loops
# poor style
n = 100
ep = zeros(n)
for i in 1:n
    ep[i] = randn()
end

# better style
n = 100
ep = zeros(n)
for i in eachindex(ep)
    ep[i] = randn()
end

# loop directly over arrays
ep_sum = 0.0 # careful to use 0.0 here, instead of 0
m = 5
for ep_val in ep[1:m]
    ep_sum = ep_sum + ep_val
end
ep_mean = ep_sum / m

# check with built-in function
ep_mean ≈ mean(ep[1:m])
isapprox(ep_mean, mean(ep[1:m])) # equivalent
ep_mean ≈ sum(ep[1:m]) / m

### User-defined functions
# poor style
function generatedata(n)
    ep = zeros(n)
    for i in eachindex(ep)
        ep[i] = (randn())^2 # squaring the result
    end
    return ep
end
data = generatedata(10)
plot(data)


# better style
function generatedata(n)
    ep = randn(n)   # use built in function
    return ep .^ 2  # square the fuction
end
data = generatedata(5)

# good style
generatedata(n) = randn(n) .^ 2
data = generatedata(5)
print(data)


# good style
f(x) = x^2 # simple square function
generatedata(n) = f.(randn(n)) # broadcasts on f
data = generatedata(5)

generatedata(n, gen) = gen.(randn(n)) # broadcasts on gen
f(x) = x^2                            # simple square function
data = generatedata(5, f)             # applies f


# another one
using Distributions
function plothistogram(distribution, n)
    ep = rand(distribution, n)  # n draws from distribution
    histogram(ep)
end

lp = Laplace()
plothistogram(lp, 500)


### Fixed point example
# poor style
p = 1.0 # note 1.0 rather than 1
beta = 0.9
maxiter = 1000
tolerance = 1.0E-7
v_iv = 0.8 # initial condition

# setup the algorithm
v_old = v_iv
normdiff = Inf
iter = 1
while normdiff > tolerance && iter <= maxiter
    v_new = p + beta * v_old # the f(v) map
    normdiff = norm(v_new - v_old)

    # replace and continue
    v_old = v_new
    iter = iter + 1
end
println("Fixed point = $v_old |f(x) - x| = $normdiff in $iter iterations")


# alternative
# setup the algorithm
p = 1.0 # note 1.0 rather than 1
beta = 0.9
maxiter = 1000
tolerance = 1.0E-7
v_iv = 0.8 # initial condition

v_old = v_iv
normdiff = Inf
iter = 1
for i in 1:maxiter
    v_new = p + beta * v_old # the f(v) map
    normdiff = norm(v_new - v_old)
    if normdiff < tolerance # check convergence
        iter = i
        break # converged, exit loop
    end
    # replace and continue
    v_old = v_new
end
println("Fixed point = $v_old |f(x) - x| = $normdiff in $iter iterations")




# better, but still poor style
function v_fp(beta, ρ, v_iv, tolerance, maxiter)
    # setup the algorithm
    v_old = v_iv
    normdiff = Inf
    iter = 1
    while normdiff > tolerance && iter <= maxiter
        v_new = p + beta * v_old # the f(v) map
        normdiff = norm(v_new - v_old)

        # replace and continue
        v_old = v_new
        iter = iter + 1
    end
    return (v_old, normdiff, iter) # returns a tuple
end

# some values
p = 1.0 # note 1.0 rather than 1
beta = 0.9
maxiter = 1000
tolerance = 1.0E-7
v_initial = 0.8 # initial condition

v_star, normdiff, iter = v_fp(beta, p, v_initial, tolerance, maxiter)
println("Fixed point = $v_star |f(x) - x| = $normdiff in $iter iterations")

  


# Passing a function - the function is still specific to our problem
# A key feature of languages like Julia, is the ability to efficiently handle functions
# passed to other functions.

# better style
function fixedpointmap(f, iv, tolerance, maxiter)
    # setup the algorithm
    x_old = iv
    normdiff = Inf
    iter = 1
    while normdiff > tolerance && iter <= maxiter
        x_new = f(x_old) # use the passed in map
        normdiff = norm(x_new - x_old)
        x_old = x_new
        iter = iter + 1
    end
    return (x_old, normdiff, iter)
end

# define a map and parameters
p = 1.0
beta = 0.9
f(v) = p + beta * v # note that p and beta are used in the function!

maxiter = 1000
tolerance = 1.0E-7
v_initial = 0.8 # initial condition

v_star, normdiff, iter = fixedpointmap(f, v_initial, tolerance, maxiter)
println("Fixed point = $v_star |f(x) - x| = $normdiff in $iter iterations")


# named function parameters and names tuples
# good style
function fixedpointmap(f, iv; tolerance = 1E-7, maxiter = 1000)
    # setup the algorithm
    x_old = iv
    normdiff = Inf
    iter = 1
    while normdiff > tolerance && iter <= maxiter
        x_new = f(x_old) # use the passed in map
        normdiff = norm(x_new - x_old)
        x_old = x_new
        iter = iter + 1
    end
    return (; value = x_old, normdiff, iter) # A named tuple
end

# define a map and parameters
p = 1.0
beta = 0.9
f(v) = p + beta * v # note that p and beta are used in the function!

sol = fixedpointmap(f, 0.8; tolerance = 1.0E-8) # don't need to pass
println("Fixed point = $(sol.value) |f(x) - x| = $(sol.normdiff) in $(sol.iter) iterations")


# my own test
function fixedpointmap(f, iv; p = 1.0, beta = 0.9, tolerance = 1E-7, maxiter = 1000)
    # setup the algorithm
    x_old = iv
    normdiff = Inf
    iter = 1
    while normdiff > tolerance && iter <= maxiter
        x_new = f(x_old) # use the passed in map
        normdiff = norm(x_new - x_old)
        x_old = x_new
        iter = iter + 1
    end
    return (; value = x_old, normdiff, iter) # A named tuple
end

# define a map only
f(v) = p + beta * v # note that p and beta are used in the function!

sol = fixedpointmap(f, 0.8; tolerance = 1.0E-8) # don't need to pass
println("Fixed point = $(sol.value) |f(x) - x| = $(sol.normdiff) in $(sol.iter) iterations")



### using a package


















