A real-time volume cloud system.

Use raymarching to sample the density of a 3D worley noise to generate the cloud shape.And sample the density between the light and sample position to calculate the light scatter and attenuation,use Henyey-Greenstein phase function(with the angle between viewdir and light dir) and beer's law.

Phase1(Theory test): Start with generating 2D worley noise use compute shader, then add a loop to do the 3D noise. Use ray-box intersection to restrict the cloud in a box, when ray steps into the box we do the sampling.

![image](https://user-images.githubusercontent.com/56297955/152983429-0d6f44ef-20a1-45e4-b55b-c6c38773d8a8.png)
![image](https://user-images.githubusercontent.com/56297955/152983519-acaf450e-cbf8-4d8a-a2f9-2d494e66cdac.png)

Phase2(Calculate lighting): For each sample point,use the desity along the ray between the point and lightsource to get the attenuation, then caculate the scatter use Henyey-Greenstein phase function, it is a common way of approximating the complex Mie scattering phase function.

![image](https://user-images.githubusercontent.com/56297955/152993059-db0e910f-9bd2-4434-ad65-95b0c867b22f.png)

![image](https://user-images.githubusercontent.com/56297955/152993088-c9881e7f-a5d5-4a85-9e44-7180dd2289e6.png)

![image](https://user-images.githubusercontent.com/56297955/152990589-11305b10-25ad-403b-8919-14294823d90b.png)


Later work : Use SDF to control the shape...Still working on....
