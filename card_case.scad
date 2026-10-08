// Carry case for a stack of business cards: a base tray and a friction-fit lid.
// The lid slides over a lip on the base, so the outside is flush when closed.
// The lid top shows the name and the base bottom the contact QR code, as flush inlays for an AMS.
// Print both parts as laid out (lid upside down), no supports.

use <fonts/Inter-Bold.ttf>
use <lib/qr.scad>
include <contact.scad>

/* [Export] */
// print = single color, no inlays; body / inlay = separate STLs for a two-color print
part = "print"; // [print, body, inlay, assembled]
gap  = 10;      // between the parts in the print layout
body_color  = "white";  // keep light: scanners need dark QR modules on a light background
inlay_color = "black";

/* [Cards] */
card_width     = 85;
card_height    = 55;
card_thickness = 2;
card_count     = 10;

/* [Fit] */
card_clearance  = 0.5;   // around the stack, per side
stack_clearance = 1;     // above the stack
fit_clearance   = 0.15;  // between lip and lid, per side; raise if the lid is too tight

/* [Case] */
wall          = 2;    // five 0.4 mm lines
plate         = 1.2;  // floor and lid top
corner_radius = 3;
chamfer       = 0.4;  // edges that touch the print bed
lip_height    = 4;
base_fraction = 0.4;  // share of the inner height in the base; the rest of the stack sticks out to grip

/* [Inlays] */
inlay_depth    = 0.4;   // two 0.2 mm layers, flush with the outside
name_font      = "Inter:style=Bold";
name_size      = 5;
qr_size        = 45;
qr_error_correction = "M";  // [L, M, Q, H]
qr_shrink      = 0.05;  // offsets first-layer squish so dark squares don't merge

inner   = [card_width + 2 * card_clearance,
           card_height + 2 * card_clearance,
           card_count * card_thickness + stack_clearance];
outer   = [inner.x + 2 * wall, inner.y + 2 * wall];
total_h = inner.z + 2 * plate;
split_z = plate + inner.z * base_fraction;
lid_h   = total_h - split_z;
lip_t   = wall / 2;
lip_gap = 0.3;  // keeps the lip from bottoming out, so the lid seats on the base rim
eps     = 0.01;
lid_offset = [outer.x + gap, 0, 0];

assert(corner_radius > wall, "corner_radius must exceed wall");
assert(lid_h - lip_height - lip_gap > plate, "lip_height too large for the lid");

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
            linear_extrude(split_z + lip_height) footprint(wall - lip_t);
        }
        translate([0, 0, plate]) linear_extrude(total_h) footprint(wall);
        if (pocket) inlay_pocket() base_inlay_2d();
    }
}

// Modeled in print orientation, with the outside of the lid on the bed.
module lid(pocket = false) {
    difference() {
        chamfered_block(lid_h);
        translate([0, 0, plate]) linear_extrude(lid_h) footprint(wall);
        translate([0, 0, lid_h - lip_height - lip_gap])
            linear_extrude(lid_h) footprint(wall - lip_t - fit_clearance);
        if (pocket) inlay_pocket() lid_inlay_2d();
    }
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
    translate([0, 0, -eps]) linear_extrude(inlay_depth + eps) children();
}

module inlay() {
    linear_extrude(inlay_depth) children();
}

// Turned over like the real part; a mirror would also reverse the name.
module closed_lid() {
    translate([outer.x, 0, total_h]) rotate([0, 180, 0]) {
        color(body_color)  lid(pocket = true);
        color(inlay_color) inlay() lid_inlay_2d();
    }
}

// The single-color export omits the inlays because they would be invisible in one color.
if (part == "print") {
    color(body_color) {
        base(pocket = $preview);
        translate(lid_offset) lid(pocket = $preview);
    }
    if ($preview) color(inlay_color) {
        inlay() base_inlay_2d();
        translate(lid_offset) inlay() lid_inlay_2d();
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
if (part == "assembled") {
    color(body_color)  base(pocket = true);
    color(inlay_color) inlay() base_inlay_2d();
    closed_lid();
}
