// Carry case for a stack of business cards: a base tray and a lid that clicks onto it.
// The lid slides over a lip on the base, so the outside is flush when closed. Bumps on the
// lip snap into grooves in the lid, so the walls carry no load once closed and don't wear loose.
// The lid top shows the name and the base bottom the contact QR code, as inlays for an AMS.
// The inlays sit behind a solid first layer, the cover, so the first layer prints cleanly.
// Print both parts as laid out (lid upside down), no supports.

use <fonts/Inter-Bold.ttf>
use <lib/qr.scad>
include <contact.scad>

/* [Export] */
// print = single color, no inlays; body / inlay / cover = separate STLs for a multi-color print;
// fit_test = floor, top, and rims of both parts, to tune the detent quickly
part = "print"; // [print, body, inlay, cover, assembled, fit_test]
gap  = 10;      // between the parts in the print layout
body_color  = "white";  // keep light: scanners need dark QR modules on a light background
inlay_color = "black";
cover_color = "white";  // translucent or natural PLA gives the most contrast

/* [Cards] */
card_width     = 85;
card_height    = 55;
card_thickness = 2;
card_count     = 10;

/* [Fit] */
card_clearance  = 0.5;   // around the stack, per side
stack_clearance = 1;     // above the stack
fit_clearance   = 0.1;   // between lip and lid, per side; the detent holds the lid, not friction

/* [Detent] */
detent_height    = 0.4;  // how far each bump sticks out; raise for a firmer click
detent_length    = 20;   // along each long side
detent_flat      = 0.4;  // flat top of the bump; the flanks are 45 degrees
detent_clearance = 0.1;  // extra room in the groove around the bump
lead_in          = 0.4;  // chamfer on top of the lip, so the lid starts easily
fit_test_margin  = 2;    // full wall kept below the rim in the fit test

/* [Case] */
wall          = 2;    // five 0.4 mm lines
plate         = 1.2;  // floor and lid top
corner_radius = 3;
chamfer       = 0.4;  // edges that touch the print bed
lip_height    = 4;
base_fraction = 0.4;  // share of the inner height in the base; the rest of the stack sticks out to grip

/* [Inlays] */
inlay_depth    = 0.4;   // two 0.2 mm layers
name_font      = "Inter:style=Bold";
name_size      = 5;
qr_size        = 45;
qr_error_correction = "M";  // [L, M, Q, H]
qr_shrink      = 0.05;  // keeps dark squares from merging
// Must equal the slicer's initial layer height; 0 puts the inlays flush on the outside.
cover_thickness = 0.2;

inner   = [card_width + 2 * card_clearance,
           card_height + 2 * card_clearance,
           card_count * card_thickness + stack_clearance];
outer   = [inner.x + 2 * wall, inner.y + 2 * wall];
total_h = inner.z + 2 * plate;
split_z = plate + inner.z * base_fraction;
lid_h   = total_h - split_z;
lip_t   = wall / 2;
lip_inset = wall - lip_t;  // from the outside to the outer face of the lip
lip_gap = 0.3;  // keeps the lip from bottoming out, so the lid seats on the base rim
eps     = 0.01;
lid_offset = [outer.x + gap, 0, 0];
detent_z   = split_z + lip_height / 2;

assert(corner_radius > wall, "corner_radius must exceed wall");
assert(lid_h - lip_height - lip_gap > plate, "lip_height too large for the lid");
assert(detent_height > fit_clearance, "detent_height must exceed fit_clearance, or the lid won't click");
assert(2 * detent_height + detent_flat < lip_height - lead_in, "detent too tall for the lip");

$fn = 64;

module rounded_rect(w, h, r) {
    offset(r = r) offset(delta = -r) square([w, h]);
}

module footprint(inset = 0) {
    offset(delta = -inset) rounded_rect(outer.x, outer.y, corner_radius);
}

module chamfered_block(h) {
    hull() {
        linear_extrude(h) footprint(chamfer);
        translate([0, 0, chamfer]) linear_extrude(h - chamfer) footprint();
    }
}

module base(pocket = false) {
    difference() {
        union() {
            chamfered_block(split_z);
            hull() {
                linear_extrude(split_z + lip_height - lead_in) footprint(lip_inset);
                linear_extrude(split_z + lip_height) footprint(lip_inset + lead_in);
            }
            detents();
        }
        translate([0, 0, plate]) linear_extrude(total_h) footprint(wall);
        if (pocket) inlay_pocket() base_inlay_2d();
        if (pocket && cover_thickness > 0) below_cover();
    }
}

// Modeled in print orientation, with the outside of the lid on the bed.
module lid(pocket = false) {
    difference() {
        chamfered_block(lid_h);
        translate([0, 0, plate]) linear_extrude(lid_h) footprint(wall);
        translate([0, 0, lid_h - lip_height - lip_gap])
            linear_extrude(lid_h) footprint(lip_inset - fit_clearance);
        to_lid_frame() detents(grow = detent_clearance);
        if (pocket) inlay_pocket() lid_inlay_2d();
        if (pocket && cover_thickness > 0) below_cover();
    }
}

// Bumps on the outer face of the lip, centered on both long sides; grow > 0 gives the grooves.
// The 45-degree flanks and tapered ends print without supports and let the lid slide over.
module detents(grow = 0) {
    h = detent_height + grow;
    for (side = [[lip_inset, -1], [outer.y - lip_inset, 1]])
        translate([outer.x / 2, side[0], detent_z])
            scale([1, side[1], 1])
                hull() {
                    translate([-detent_length / 2 - grow, -lip_t, -h - detent_flat / 2])
                        cube([detent_length + 2 * grow, lip_t, 2 * h + detent_flat]);
                    translate([-detent_length / 2 + h - grow, 0, -detent_flat / 2 - grow])
                        cube([detent_length - 2 * h + 2 * grow, h, detent_flat + 2 * grow]);
                }
}

// Maps the closed-case frame onto the lid's print orientation; inverse of closed_lid().
module to_lid_frame() {
    rotate([0, 180, 0]) translate([-outer.x, 0, -total_h]) children();
}

// Both inlays face the bed, so they are mirrored to read correctly from outside.
module base_inlay_2d() {
    translate([outer.x / 2, outer.y / 2])
        mirror([1, 0])
            offset(delta = -qr_shrink)
                offset(delta = 0.01)
                    qr(vcard, error_correction = qr_error_correction,
                       width = qr_size, height = qr_size, thickness = 0, center = true);
}

module lid_inlay_2d() {
    translate([outer.x / 2, outer.y / 2])
        mirror([1, 0])
            text(name_text, size = name_size, font = name_font, halign = "center", valign = "center");
}

module inlay_pocket() {
    translate([0, 0, cover_thickness - eps]) linear_extrude(inlay_depth + eps) children();
}

module inlay() {
    translate([0, 0, cover_thickness]) linear_extrude(inlay_depth) children();
}

module below_cover() {
    translate([-1, -1, -1]) cube([outer.x + 2, outer.y + 2, cover_thickness + 1]);
}

// Same for the base and the lid, because both have the same outer footprint and chamfer.
module cover() {
    intersection() {
        chamfered_block(1);
        below_cover();
    }
}

// Semi-transparent in the preview so the inlays show through.
module preview_cover() {
    if (cover_thickness > 0) color(cover_color, 0.6) cover();
}

// Turned over like the real part; a mirror would also reverse the name.
module closed_lid() {
    translate([outer.x, 0, total_h]) rotate([0, 180, 0]) {
        color(body_color)  lid(pocket = true);
        color(inlay_color) inlay() lid_inlay_2d();
        preview_cover();
    }
}

// The single-color export omits the inlays because they would be invisible in one color.
if (part == "print") {
    color(body_color) {
        base(pocket = $preview);
        translate(lid_offset) lid(pocket = $preview);
    }
    if ($preview) {
        color(inlay_color) {
            inlay() base_inlay_2d();
            translate(lid_offset) inlay() lid_inlay_2d();
        }
        preview_cover();
        translate(lid_offset) preview_cover();
    }
}
if (part == "body") {
    base(pocket = true);
    translate(lid_offset) lid(pocket = true);
}
if (part == "inlay") {
    inlay() base_inlay_2d();
    translate(lid_offset) inlay() lid_inlay_2d();
}
if (part == "cover" && cover_thickness > 0) {
    cover();
    translate(lid_offset) cover();
}
if (part == "assembled") {
    color(body_color)  base(pocket = true);
    color(inlay_color) inlay() base_inlay_2d();
    preview_cover();
    closed_lid();
}
if (part == "fit_test") {
    squashed(split_z - fit_test_margin) base();
    translate(lid_offset) squashed(lid_h - lip_height - lip_gap - fit_test_margin) lid();
}

// Keeps the floor and the rim but drops the wall between them, so the test flexes like the full part.
module squashed(cut) {
    below(plate) children();
    translate([0, 0, plate - cut]) above(cut) children();
}

module below(z) {
    intersection() {
        children();
        translate([-1, -1, -1]) cube([outer.x + 2, outer.y + 2, z + 1]);
    }
}

module above(z) {
    intersection() {
        children();
        translate([-1, -1, z]) cube([outer.x + 2, outer.y + 2, total_h]);
    }
}
