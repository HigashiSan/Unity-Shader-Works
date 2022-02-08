A real-time volume cloud system.

Use raymarching to sample the density of a 3D worley noise to generate the cloud shape.And sample the density between the light and sample position to calculate the light scatter and attenuation,use Henyey-Greenstein phase function(with the angle between viewdir and light dir) and beer's law.

Phase1(Theory test): Start with generating 2D worley noise use compute shader, then add a loop to do the 3D noise. Use ray-box intersection to restrict the cloud in a box, when ray steps into the box we do the sampling.

Phase2(Calculate lighting)

Later work : Use SDF to control the shape...Working....
