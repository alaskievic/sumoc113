using Pkg; pkgs = ["BenchmarkTools", "Enzyme", "ForwardDiff", "Plots"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using LinearAlgebra, Statistics
using ForwardDiff, Enzyme, Test
using BenchmarkTools
using Plots

### A simple differentiation ###
using ForwardDiff

function f(a, b; N = 50)
    r = range(a, b, length = N) # one
    return mean(r)
end

# d/db f(0.0, b) = 1/2
Df(x) = ForwardDiff.derivative(y -> f(0.0, y), x)

@show f(0.0, 3.0)
@show f(0.0, 3.1)
Df(3.0)

### Differentiable programming is the natural evolution of automatic differentiation ###
h(x) = sin(x[1]) + x[1] * x[2] + sinh(x[1] * x[2]) # multivariate
x = [1.4 2.2]
@show ForwardDiff.gradient(h, x) # use AD, seeds from x

#Or, can use complicated functions of many variables
f(x) = sum(sin, x) + prod(tan, x) * sum(sqrt, x)
g = (x) -> ForwardDiff.gradient(f, x); # g() is now the gradient
g(rand(5)) # gradient at a random point
# ForwardDiff.hessian(f,x') # or the hessian

# ForwardDiff.jl
function squareroot(x) #pretending we don't know sqrt()
    z = copy(x) # Initial starting point for Newton’s method
    while abs(z * z - x) > 1e-13
        z = z - (z * z - x) / (2z)
    end
    return z
end
squareroot(2.0)

dsqrt(x) = ForwardDiff.derivative(squareroot, x)
dsqrt(2.0)

# Reverse mode AD
# Unlike forward-mode auto-differentiation, 
# reverse-mode is very difficult to implement efficiently, 
# and many variations on the best approach exist













