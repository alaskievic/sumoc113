### My Own Monte Carlo Integration Example ###
using Pkg; pkgs = ["Distributions"]; all(haskey.(Ref(Pkg.project().dependencies), pkgs)) || Pkg.add(pkgs)
using Distributions

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



# A function #
function Monte(radius = 1)
    dist =  Uniform(-radius, radius)
    x = rand(dist, throws)
    y = rand(dist, throws)
    inside_circle = count(hypot.(x, y) .<= radius)

    # Calculate area and print; should be closer to Pi with increasing number of throws
    area = (2 * radius)^2 * inside_circle / throws
    return(area)
end

throws = 10^1::10^8
Monte(throws = 
10^7)




