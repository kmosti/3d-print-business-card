// Desk stand for a stack of 3D-printed business cards.
// Cards stand on their long edge and lean back. Print upright, no supports.

/* [Cards] */
card_width     = 85;
card_height    = 55;
card_thickness = 2;
card_count     = 10;

/* [Fit] */
width_clearance = 0.6;  // per side
stack_clearance = 1.5;  // total, front to back

/* [Holder] */
tilt         = 15;   // degrees the cards lean back from vertical
wall         = 2.4;  // six 0.4 mm lines
floor_height = 2.4;  // at the lowest point of the pocket
front_lip    = 5;    // covers only the card border, so the front card stays readable
back_height  = 30;   // supports a bit more than half the card height
corner_radius = 3;
chamfer       = 0.4;  // bottom edge, counters first-layer squish

inner_w = card_width + 2 * width_clearance;
inner_d = card_count * card_thickness + stack_clearance;
outer_w = inner_w + 2 * wall;

// Pocket corners in the side profile (y = depth, z = height).
// The pocket floor is perpendicular to the cards, so it slopes down towards the back.
p_front = [wall, floor_height + inner_d * sin(tilt)];
p_back  = [wall + inner_d * cos(tilt), floor_height];

front_top_z = p_front[1] + front_lip;
outer_d     = p_back[0] + (back_height - floor_height) * tan(tilt) + wall / cos(tilt);

assert(back_height > front_top_z, "back_height must exceed the front wall height");

$fn = 64;

module rounded_rect(w, h, r) {
    offset(r = r) offset(delta = -r) square([w, h]);
}

module side_profile() {
    polygon([[0, 0], [0, front_top_z], [outer_d, back_height], [outer_d, 0]]);
}

module footprint_prism() {
    hull() {
        translate([chamfer, chamfer, 0])
            linear_extrude(back_height)
                rounded_rect(outer_w - 2 * chamfer, outer_d - 2 * chamfer, corner_radius - chamfer);
        translate([0, 0, chamfer])
            linear_extrude(back_height - chamfer)
                rounded_rect(outer_w, outer_d, corner_radius);
    }
}

module pocket() {
    translate([wall, p_front[0], p_front[1]])
        rotate([-tilt, 0, 0])
            cube([inner_w, inner_d, 2 * card_height]);
}

difference() {
    intersection() {
        rotate([90, 0, 90]) linear_extrude(outer_w) side_profile();
        footprint_prism();
    }
    pocket();
}
