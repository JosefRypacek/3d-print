/*
 * Copyright 2023 Josef Rypáček.
 */

// Using fillet_* modules from utils.scad may lead to OpenSCAD errors. Read comments in utils.scad if you got the issue. 
use <utils.scad>

/*
 * Parametric flat radiator hook
 * Default values are for Korado koratherm AQUAPANEL (bathroom radiator) with approx. dimensions of rib 70x12 mm.
 * - I advise increasing length of B and stick anti-slip pad on C.
 *
  _______________
 |   _________   |
 |  |    C    |  |
 |  |         |  |      __
 |  |        D|  |     |  |
 |  |         |  |    F|  |
 |  |        _|  |__E__|  |
 |  |B        |___________|
 |  |
 |  |
 |  |
 |  |
 |  |_A_
 |______| <- thickness
 * 
 * @param thickness         Thickness of the hook
 * @param width             Width of the hook
 * @param A
 * @param B
 * @param C
 * @param D
 * @param E
 * @param F
 * @param squareShape       Shape of front hook (true/false)
 * @param backBend          Cutout in the back for convex radiator [mm] 
 * @param outerRadius       Fillet and chamger of exterior edges
 * @param innerRadius       Fillet of interior edges
 */
 
$fn = $preview ? 8: 64;

module roundedHook(
    thickness = 5,
    width = 15,
    A = 7,
    B = 70.5 + 0.65, // 70.5 without anti-slip pad
    C = 11.75,
    D = 20,
    E = 10.5,
    F = 11,
    squareShape = true,
    backBend = 0.7,
    outerRadius = 2,
    innerRadius = 1,
){
    eRadius = 0.001;

    oR = min(thickness/2 - eRadius, outerRadius); // can't be >= (smallest thickness / 2)
    iR = min(min(C/2, E/2) - eRadius, innerRadius); // can't be >= (distance between two facets / 2)    
    backBend = min(thickness - 2*oR - eRadius, backBend); // take outer radius into accout as we can't get 0 thickness during fillet...
    
    maxDistanceFromCenter = max(thickness+C+thickness+E+thickness, thickness+B+thickness+max(0, F-D-thickness)+0, width);


    // METHOD 1 - exterior fillet after interior fillet
    // - this usualy work better (= without errors) than method 2
    // - time to render (F6) with $fn=32: 1:07, 1:10, 2:38, 3:20, 1:25
    
//    if (false) // comment out this line to use this method
    fillet_exterior() {
        fillet_interior(iR, maxDistanceFromCenter)
        hook(thickness, width, A, B, C, D, E, F, squareShape, backBend);
        object_for_fillet_and_chamfer(oR);
    }
    
    
    
    // METHOD 2 - interior fillet after exterior fillet    
    // - time to render (F6) with $fn=32: 7:35, 4:43, 16:57, 15:57, 10:10

    if (false) // comment out this line to use this method
    fillet_interior(iR, maxDistanceFromCenter)
    fillet_exterior() {
        hook(thickness, width, A, B, C, D, E, F, squareShape, backBend); 
        object_for_fillet_and_chamfer(oR);
    }

    

    // METHOD 3 - faster exterior fillet, but need to create initial hook thinner
    // - the only minkowski is a simple way (not ideal) to create roundness, but need to create thiner object that will be englared
    // - time to render (F6) with $fn=32: 2:34, 5:01, 4:07, 12:20, 8:23

    if (false) // comment out this line to use this method
    fillet_interior(iR, maxDistanceFromCenter)
    translate([oR, oR, oR]) minkowski() // EXTERIOR FILLET in Z axis + EXTERIOR CHAMFER in X and Y axes
    {
        hook(thickness-2*oR, width-2*oR, A, B+2*oR, C+2*oR, D+2*oR, E+2*oR, F, squareShape, backBend);
        object_for_fillet_and_chamfer(oR);
    }
}

module hook(thickness, width, A, B, C, D, E, F, squareShape, backBend){
    
    // do not allow zero thickness
    backBend=min(thickness - 0.01, backBend);
    
    // back bottom
    cube([thickness+A, thickness, width]);

    // back
    difference(){
        translate([0, thickness, 0]) cube([thickness, B, width]);
        radiusDiv = 32; // gradient of bend
        translate([B/radiusDiv+thickness-backBend,thickness+B/2, -1]) scale([1,radiusDiv/2, 1]) rotate([0, 0, 90]) cylinder(h=width+2, r=B/radiusDiv);
    }

    // top
    translate([0, thickness+B, 0]) cube([thickness+C+thickness, thickness, width]);
    
    // mid
    translate([thickness+C, thickness+B-D, 0]) cube([thickness, D, width]);
    
    // front bottom
    if (squareShape == true) {
        translate([thickness+C, thickness+B-D-thickness, 0]) cube([thickness+E+thickness, thickness, width]);
    } else {
        inner_radius=E/2;
        translate([thickness+C, thickness+B-D, 0]) difference() {
            translate([inner_radius+thickness, 0, 0]) cylinder(h=width, r=inner_radius+thickness);
            translate([inner_radius+thickness, 0, -1]) cylinder(h=width+2, r=inner_radius);
            translate([-1, 0, -1]) cube([2*inner_radius+2*thickness+2, inner_radius+thickness+1, width+2]);
        }
    }
    
    // front
    translate([thickness+C+thickness+E, thickness+B-D, 0]) cube([thickness, F, width]);
}

roundedHook();