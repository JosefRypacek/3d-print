/*
 * Copyright 2023 Josef Rypáček.
 */

//
// Combination of several properties (e.g. object, radius, $fn) may cause weird errors I was not able to fix.
// - try F6 instead of F5 or change some property as described above
//
// ERROR: CGAL error in CGAL_Nef_polyhedron3(): CGAL ERROR: assertion violation! Expr: e_below != SHalfedge_handle() File: ...../CGAL/Nef_3/SNC_FM_decorator.h Line: 427
// ERROR: The given mesh is not closed! Unable to convert to CGAL_Nef_Polyhedron.



// INTERIOR FILLET in Z axis
module fillet_interior(radius=1, maxDistanceFromCenter=100)
{
    eCube = 1; // to not remove facets (0.001 was working during my testing, but there is no reason to keep the number low)
    
    render()
    difference()
    {
        // object + 2*radius <= smallerCube <= biggerCube
        smallerCube = 2*maxDistanceFromCenter + max(2*radius, 1) + eCube/2; // I choose something between just to be sure
        cube([smallerCube, smallerCube, smallerCube], center=true);
        minkowski()
        {   
            difference()
            {
                // this cube must be > than object after minkowski - object is englared by cylinder (2r, h)
                biggerCube = 2*maxDistanceFromCenter + max(2*radius, 1) + eCube; 
                cube([biggerCube, biggerCube, biggerCube], center=true); 
                minkowski()
                {
                    children(0);
                    cylinder(r=radius, center=true);
                }
            }
            cylinder(r=radius, center=true);
        }
    }
}


// EXTERIOR FILLET in Z axis + EXTERIOR CHAMFER in X and Y axes
// 0. child - object to fillet
// 1. child - object used to fillet
module fillet_exterior(maxDistanceFromCenter=100)
{
    assert($children == 2, "Need two children!");

    eCube = 1; // to not remove facets (0.001 was working during my testing, but there is no reason to keep the number low)
    
    render()
    minkowski()
    {  
        difference() // create the object thinner to be englared to original size
        {
            smallerCube = 2*maxDistanceFromCenter + eCube/2;
            cube([smallerCube, smallerCube, smallerCube], center=true);
            minkowski()
            {
                difference()
                {
                    // this cube must be > than object and also > first cube to make a difference
                    biggerCube = 2*maxDistanceFromCenter + eCube; 
                    cube([biggerCube, biggerCube, biggerCube], center=true); 
                    children(0);
                }
                children(1);
            }
        }  
        children(1);
    }
}

module object_for_fillet_and_chamfer(radius=1)
{ 
    h2 = 1;
    
    translate([0,0,h2/2]) object_for_chamfer_2D(radius, radius/2); // top chamfer
    cylinder(h=h2, r=radius, center=true); // side radius
    translate([0,0,-h2/2]) rotate([180,0,0]) object_for_chamfer_2D(radius, radius/2); // bottom chamfer
}


/*
 * Returns object for chamfer on top of the object in one axis.
 * May combine / rotate to get chamfer as requred.
 *
 * If r2==0 then creates 3D triangle, else creates 3D quadrilateral - trapezoid.
 *
 * @param r1        radius = width of chamfer
 * @param r2        radius to be substracted from r1 to lower chamfer size (width and height)
 * @param angle     number of degrees (0, 90) of chamfer (use > 45° for overhang)
 * @param center    make it centered
 */
module object_for_chamfer_1D(r1=1, r2=0, angle=50, center=false)
{
    h = (r1-r2)*tan(angle);
    
    y = center ? h/2 : 0;
    rotate([90,0,0]) linear_extrude(1, center=true) polygon([[-r1,0-y], [-r2,h-y], [r2,h-y], [r1,0-y]]);
}


/*
 * Returns object for chamfer on top of the object in both X and Y axes.
 * May combine / rotate to get chamfer as requred.
 *
 * If r2==0 then creates a cone, else creates a frustum of a cone.
 *
 * @param r1        radius = width of chamfer
 * @param r2        radius to be substracted from r1 to lower chamfer size (width and height)
 * @param angle     number of degrees (0, 90) of chamfer (use > 45° for overhang)
 */
module object_for_chamfer_2D(r1=1, r2=0, angle=50, center=false)
{
    h = tan(angle) * (r1-r2);
    
    cylinder(h=h, r1=r1, r2=r2, center=center);
}