$fn=100;

module slip_ring() {
	translate([0,0,-19]) cylinder(h=19, r=11);						// Main housing
	difference() {
		translate([0,0,-2.4]) cylinder(h=2.4, r=22);					// Flange
		for (t = [0,120,240]) {
			rotate([0,0,t]) translate([17.5,0,-2.5]) cylinder(h=2.6,r=2.75);	// Mounting hole
		}
	}
	cylinder(h=9,r=3.9);													// Rotor
}


difference() {
	render(convexity=10) intersection() {
		union() {
			translate([0,0,30]) rotate([90,0,0]) cylinder(h=40,r=8, center=true);
			translate([0,0,21.75]) cube([16,40,15.5], center=true);
			difference() {
				translate([0,0,7.25]) cube([40,40,15.5], center=true);
				translate([20,-1,16]) rotate([90,0,0]) cylinder(h=42, r=12, center=true);
				translate([-20,-1,16]) rotate([90,0,0]) cylinder(h=42, r=12, center=true);
			}
		}
		cylinder(h=40, r=20);											// Main house
	}
	cylinder(h=8, r=4);													// Rotor cavity
	cylinder(h=11,r=2);													// Cable riser
	translate([0,0,10])	rotate([90,0,0]) cylinder(h=21, r=2);		// Cable channel
	translate([0,0,15.5]) rotate([90,0,0]) union() {				// Laser mounting
		cylinder(h=38,r=5.5, center=true);
		cylinder(h=20,r=5.5);
		cube(size=[2,10,41], center=true);
	}
	translate([0,0,30])	rotate([90,0,0]) union() {					// Detector mounting
		cylinder(h=38,r=5.5, center=true);
		cylinder(h=20,r=5.5);
		cube(size=[2,10,41], center=true);								// Apperture
	}
	translate([0,0,4])	rotate([0,90,240]) cylinder(h=21, r=2);	// Set Screw hole
	rotate_extrude(convexity=4) translate([20.5,2,0]) circle(1);	// Drive belt groove
}


// Slip ring§
%translate([0,0,-1]) slip_ring();

// Hat
%translate([0,0,-133.4]){
	cylinder(h=130, r=90);
	translate([0,0,-10]) cylinder(h=10, r=160);
}
