$fn=100;

module slip_ring() {
	translate([0,0,-19]) cylinder(h=19, r=11);						// Main housing
	difference() {
		translate([0,0,-2.4]) cylinder(h=2.4, r=22);					// Flange
		for (t = [0,120,240]) {
			rotate([0,0,t]) translate([17.5,0,-2.5]) cylinder(h=2.6,r=2.75);	// Mounting hole
		}
	}
	cylinder(h=9,r=3.9);												// Rotor
}


difference() {
	intersection() {
		translate([0,20,20]) rotate([90,0,0]) union() {
			intersection() {
				cylinder(h=40,r=20);
				translate([-20,0,0]) cube([40,20,40]);
			}
			translate([-20,-20,0]) cube([40,20,40]);
		}
		cylinder(h=40, r=20);												// Main house
	}
	cylinder(h=8, r=4);												// Rotor cavity
	cylinder(h=11,r=2);												// Cable riser
	translate([0,0,10])	rotate([90,0,0]) cylinder(h=21, r=2);			// Cable channel
	translate([0,0,15.5])	rotate([90,0,0]) cylinder(h=50,r=5.5, center = true);		// Laser mounting
	translate([0,0,30])	rotate([90,0,0]) union() {						// Detector mounting
		cylinder(h=38,r=5.5, center=true);
		cylinder(h=20,r=5.5);
		cube(size=[2,10,41],center=true);							// Apperture
	}
	for (t = [0,120,240]) {
		translate([0,0,6])	rotate([0,90,t]) cylinder(h=21, r=2);
	}
}


// Slip ring§
%translate([0,0,-1]) slip_ring();

// Hat
%translate([0,0,-133.4]){
	cylinder(h=130, r=90);
	translate([0,0,-10]) cylinder(h=10, r=160);
}
