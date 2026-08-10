# install the packages
using Pkg; pkgs = ["Distributions", "ForwardDiff", "LaTeXStrings", "NLsolve", "Plots", "StaticArrays"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics, Plots, LaTeXStrings
using Distributions, ForwardDiff, NLsolve, StaticArrays

### About functions ###
# In Julia, the return statement is optional, so that the following functions have identical behavior
function f1(a, b)
    return a * b
end

# When no return statement is present, the last value obtained when executing the code block is returned.
function f2(a, b)
    a * b
end

# The difference between keyword and standard (positional) arguments
# is that they are parsed and bounded by name rather than the order in the function call.
f(x; a = 1) = exp(cos(a * x))  # note the ; in the definition
f(pi; a = 2)
# The ; in this case for calling the function is optional and the last line could equivalently be f(pi, a = 2)

# If you see an argument in in julia to the right of the ; assume it is a keyword argument with the name matching the value
a = 2
f(pi; a) # equivalent to f(pi; a = a)

# Broadcasting
f(x, y) = [1, 2, 3] ⋅ x + y
f([3, 4, 5], 2)   # uses vector as first parameter
f.(Ref([3, 4, 5]), [2, 3])   # broadcasting over 2nd parameter, fixing first
println(f.(Ref([3, 4, 5]), [2, 3]))

f(x) = x^2  # local `x` in scope
x = 1:5     # not an integer
f.(x)       # broadcasts the x^2 function over the vecto


f(x; y = 1) = x + y  # `x` and `y` are names local to the `f` function
x = 0.1
y = 2
f(x; y) # the type and value of y taken from scope


# closures
twice(f, x) = f(f(x))  # applies f to itself twice
twice(x -> x^2, 2.0)

a = 5
g(x) = a * x
@show twice(g, 2.0);   # using a closure


function snapabove(g, a)
    function f(x)
        if x > a         # "a" is captured in the closure f
            return g(x)
        else
            return g(a)
        end
    end
    return f    # closure with the embedded a
end

f(x) = x^2
h = snapabove(f, 2.0)
plot(h, 0.0:0.1:3.0)


# Changing dimsension: 4-dimensional array - note how in binds column-wise
B = reshape(1:120, 2, 3, 4, 5)

# function that modifies any argument
function f(x)
    return [1 2; 3 4] * x   # matrix * column vector
end

val = [1, 2]
f(val)
# then
y = similar(val)
function f!(out, x)
    out .= [1 2; 3 4] * x
end
f!(y, val)
y



### Nothing and Missing ###
function f(x)
    if x > 0.0
        return sqrt(x)
    else
        return nothing
    end
end
x1 = 1.0
x2 = -1.0
y1 = f(x1)
y2 = f(x2)

# check results with isnothing
if isnothing(y1)
    println("f($x1) failed")
else
    println("f($x1) successful")
end

# Another example
function f(x; z = nothing)
    if isnothing(z)
        println("No z given with $x")
    else
        println("z = $z given with $x")
    end
end

f(1.0)
f(1.0, z = 3.0)



# An alternative
function f(x)
    if x > 0.0
        return x
    else
        return NaN
    end
end

f(0.1)
f(-1.0)

@show typeof(f(-1.0))
@show f(-1.0) == NaN  # note, this fails!
@show isnan(f(-1.0))  # check with this

# Missing - for Statistics
x = [3.0, missing, 5.0, missing, missing]

x = missing
@show x == missing
@show x === missing  # an exception
@show ismissing(x);

x = [1.0, missing, 2.0, missing, missing, 5.0]
@show mean(x)
@show mean(skipmissing(x))
@show coalesce.(x, 0.0);  # replace missing with 0.0;


### In-place and Immutable Types ###
y = [1 2]
y .-= 2    # y .= y .- 2, no problem

x = 5
# x .-= 2  # Fails!
x = x - 2  # subtle difference - creates a new value and rebinds the variable


# some operations
ones(2, 2) * ones(2, 2)   # matrix multiplication
ones(2, 2) .* ones(2, 2)  # element by element multiplication
ones(2, 2) ⋅ ones(2, 2)   # inner product (Frobenius)





### random number generator - returns a a column vector n random draws from a normal distribution with mean 0 and variance 1
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
# best style
using NLsolve

p = 1.0
beta = 0.9
f(v) = p .+ beta * v # broadcast the +
sol = fixedpoint(f, [0.8]; m = 0)
normdiff = norm(f(sol.zero) - sol.zero)
println("Fixed point = $(sol.zero) |f(x) - x| = $normdiff in $(sol.iterations) iterations")


# best style - 3 iterations!!!!
p = 1.0
beta = 0.9
iv = [0.8]
sol = fixedpoint(v -> p .+ beta * v, iv) # anonymous function similar to MATLAB and lambda function in Python
fnorm = norm(f(sol.zero) - sol.zero)
println("Fixed point = $(sol.zero) |f(x) - x| = $fnorm  in $(sol.iterations) iterations converged = $(sol.f_converged)")


### composing packages
eps()

# use arbitrary precision floating points
p = 1.0
beta = 0.9
iv = [BigFloat(0.8)] # higher precision

# otherwise identical
sol = fixedpoint(v -> p .+ beta * v, iv)
normdiff = norm(f(sol.zero) - sol.zero)
println("Fixed point = $(sol.zero) |f(x) - x| = $normdiff in $(sol.iterations) iterations")


### Multivariate case

# homegrown
p = [1.0, 2.0]
beta = 0.9
iv = [0.8, 2.0]
f(v) = p .+ beta * v # note that p and beta are used in the function!
sol = fixedpointmap(f, iv; tolerance = 1.0E-8)
println("Fixed point = $(sol.value) |f(x) - x| = $(sol.normdiff) in $(sol.iter) iterations")

# package
using NLsolve
p = [1.0, 2.0, 0.1]
beta = 0.9
iv = [0.8, 2.0, 51.0]
f(v) = p .+ beta * v

sol = fixedpoint(v -> p .+ beta * v, iv)
normdiff = norm(f(sol.zero) - sol.zero)
println("Fixed point = $(sol.zero) |f(x) - x| = $normdiff in $(sol.iterations) iterations")


using NLsolve, StaticArrays
p = @SVector [1.0, 2.0, 0.1] # All macros in Julia are prefixed by @ in the name, and manipulate the code prior to compilation
beta = 0.9
iv = [0.8, 2.0, 51.0]
f(v) = p .+ beta * v

sol = fixedpoint(v -> p .+ beta * v, iv)
normdiff = norm(f(sol.zero) - sol.zero)
println("Fixed point = $(sol.zero) |f(x) - x| = $normdiff in $(sol.iterations) iterations")



# Exercise 1
function factorial2(n)
    k = 1
    for i in 1:n
        k *= i  # or k = k * i
    end
    return k
end
factorial2(5)

function factorial2(x)
    for i in 1:x
        fact = n * (n-1)
        if normdiff < tolerance # check convergence
            iter = i
            break # converged, exit loop
    end
        # replace and continue
    return (fact)
end

factorial2(5)












