The Finite Time Lyapunov Spectrum (FTLS) for a 2D billiard system consists of a set of 4 numbers $\lambda_i \, , \{ i = 1, ...,4 \}$ that characterize the chaoticity of the billiard. They depend on the initial condition and the total time of integration.

It can be shown theoretically that two of these exponents must be zero ($\lambda_2$ =$\lambda_3$ = 0) and the other two are paired in such a way that they sum up to zero, i.e. $\lambda_1 =  -\lambda_4$).

The function provided to calculate the FTLS is
```julia
lyapunovspectrum!(p::AbstractParticle, bt::Billiard, t)
```
and it returns an array with the 4 Lyapunov exponents.

Here its basic use is illustrated
```julia
using DynamicalBilliards

radius = 1.0
l = 2.0

bt = Billiard(billiard_polygon(6, l; setting = "periodic")..., Disk([0., 0.], radius))

p = randominside(bt)
t = 1000.0

exps = lyapunovspectrum(p, bt, t)
```
```
0.694…
0.0000395…
-0.00128…
-0.692…
```


The following code is for a family of polygonal billiards (hexagonal unit cell) parameterized by the space between the disks.

```julia
using DynamicalBilliards
using PyPlot

t = 5000.0
radius = 1.0

spaces = 2.0:0.1:4.4 #Distances between adjacent disks
lyap_time = zeros(spaces) #Array where the exponents will be stored

for (i, space) in enumerate(spaces)
    bt = billiard_polygon(6, space/(sqrt(3)); setting = "periodic")
    disc = Disk([0., 0.], radius)
    billiard = Billiard(bt.obstacles..., disc)
    p = randominside(billiard)
    exps = lyapunovspectrum(p, billiard, t)
    lyap_time[i] = exps[1]
end

plot(spaces, lyap_time, "*-")
```

The plot of the maximum exponent is displayed below and it can be compared with the results reported by [Gaspard et. al](https://journals.aps.org/pre/abstract/10.1103/PhysRevE.51.5332) (see figure 7, also displayed below) for the average over an ensemble.

![lyapunov](https://i.imgur.com/LuwksbL.png)
![gaspard](https://i.imgur.com/kBDh0OJ.png)
