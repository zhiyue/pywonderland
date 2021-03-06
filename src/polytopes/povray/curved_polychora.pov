// Persistence of Vision Ray Tracer Scene Description File
// Vers: 3.7
// Date: 2018/04/22
// Auth: Zhao Liang mathzhaoliang@gmail.com

#version 3.7;

#include "colors.inc"
#include "helpers.inc"

global_settings {
    assumed_gamma 2.2
}

background { color SkyBlue }

#declare vRad = 0.02;
#declare eRad = 0.01;
#declare numSegments = 40;
#declare faceTransmit = 0.7;
#declare faceThreshold = 3.0;

#declare vert_finish = finish { specular 1 roughness 0.003 phong 0.9 phong_size 100 diffuse 0.7 reflection 0.1 }
#declare edge_finish = finish { ambient 0 diffuse 0.6 specular 0.3 reflection 0.2 roughness 0.01 }
#declare face_finish = finish { diffuse 0.8 specular 0.1 reflection 0.2 roughness 0.1 }
#declare vertex_tex = texture { pigment{ rgb 0.05 } finish { vert_finish }}
#declare edge_colors = array[4] { Orange, Green, Red, Blue };
#declare face_colors = array[6] { Pink, Violet, Yellow, Maroon, Orchid, Brown }

#macro edge_tex(i)
    texture { pigment { edge_colors[i] } finish { edge_finish } }
#end

#macro face_tex(i)
    texture { pigment { face_colors[i] transmit faceTransmit } finish { face_finish } }
#end

#macro getSize(q)
    #local len = vlength(q);
    (1.0 + len * len) / 4
#end

#macro Vertex(p)
    #local q = vProj4d(p);
    sphere {
        q, vRad*getSize(q)
        texture{ vertex_tex }
    }
#end

#macro Edge(ind, p1, p2)
    sphere_sweep {
        cubic_spline
        numSegments + 3,
        vProj4d(p1), eRad*getSize(vProj4d(p1))
        #local i=0;
        #while (i < numSegments)
            #local q = vProj4d(p1 + i*(p2-p1)/numSegments);
            q, eRad*getSize(q)
            #local i=i+1;
        #end
        vProj4d(p2), eRad*getSize(vProj4d(p2))
        vProj4d(p2), eRad*getSize(vProj4d(p2))
        edge_tex(ind)
    }
#end

#macro FlatFace(i, num, pts, faceSize, faceColor)
    #if (faceSize > faceThreshold)
        polygon {
          num+1,
            #local ind=0;
            #while (ind<num)
                vProj4d(pts[ind])
                #local ind=ind+1;
            #end
            vProj4d(pts[0])
            face_tex(i)
        }
    #end
#end

#macro BubbleFace(i, num, pts, sphereCenter, sphereRadius, faceSize, faceColor)
    #if (faceSize > faceThreshold)
        #local rib = 0;
        #local ind = 0;
        #while (ind < num)
            #local rib = rib + pts[ind];
            #local ind = ind+1;
        #end
        #local rib3d = vProj4d(rib);

        #local ind = 0;
        #local planes = array[num];
        #local pts3d = array[num];
        #local dists = array[num];
        #local sides = array[num];
        #while (ind < num)
            #local ind2 = ind + 1;
            #if (ind2 = num)
                #local ind2 = 0;
            #end
            #local planes[ind] = getClippingPlane(pts[ind], pts[ind2]);
            #local pts3d[ind] = vProj4d(pts[ind]);
            #local dists[ind] = distancePointPlane(0, pts3d[ind], planes[ind]);
            #local sides[ind] = onSameSide(rib3d, pts3d[ind], planes[ind]);
            #if (sides[ind] != true)
                #local planes[ind] = -planes[ind];
            #end
            #local ind = ind+1;
        #end

        #local col = vnormalize(rib3d);
        sphere {
            sphereCenter, sphereRadius
            face_tex(i)
            #local ind = 0;
            #while (ind < num)
                clipped_by { plane { -planes[ind], dists[ind] } }
                #local ind = ind+1;
            #end
        }
    #end
#end

union {
    #include "polychora-data.inc"
    scale 1/extent
}

camera {
    location <0, 2, 1> * 1.5
    look_at <0, 0, 0>
    angle 40
    up y*image_height
    right x*image_width
}

light_source {
    <0, 3, 1> * 100
    color rgb 1
}
