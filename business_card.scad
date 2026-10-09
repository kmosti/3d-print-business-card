// 3D-printable business card.
// Print face up, no supports. Overall thickness is card_thickness at the border;
// the inner field is thinner (card_thickness - border_height) to save material.

use <fonts/Inter-Bold.ttf>
use <fonts/Inter-SemiBold.ttf>
use <fonts/fa-solid-900.ttf>
use <fonts/fa-brands-400.ttf>
use <lib/qr.scad>
include <contact.scad>

/* [Export] */
// all = single-color STL; body / accent / back / cover = separate STLs for a multi-color print
part = "all"; // [all, body, accent, back, cover]
body_color   = "white";  // keep light: scanners need dark QR modules on a light background
accent_color = "black";
cover_color  = "white";  // translucent or natural PLA gives the most QR contrast

/* [Card] */
card_width     = 85;
card_height    = 55;
card_thickness = 2;     // total thickness at the raised border
corner_radius  = 2;
chamfer        = 0.4;   // 45-degree chamfer on top and bottom outer edges

/* [Relief] */
border_height = 0.8;    // border rises this much above the card surface
border_width  = 2;
text_height   = 0.6;    // text rises this much above the card surface

/* [Text] */
name_font = "Inter:style=Bold";
body_font = "Inter:style=SemiBold";  // heavier weights keep strokes >= 0.4 mm nozzle width

name_size     = 4.8;
title_size    = 3.6;
subtitle_size = 3;

text_margin = 5;        // left margin from the inner edge of the border
name_y      = card_height - 11;  // text baselines
title_y     = name_y - 7.5;
subtitle_y  = title_y - 5;
subtitle_line_spacing = 4.5;

// OpenSCAD text() can't break lines, so a list of strings gives one line each.
subtitle_lines = subtitle_text == "" ? [] : is_list(subtitle_text) ? subtitle_text : [subtitle_text];

/* [Contact] */
// Color emoji can't be extruded, so the icons are Font Awesome glyphs.
icon_font     = "Font Awesome 6 Free:style=Solid";
brand_font    = "Font Awesome 6 Brands:style=Regular";
email_icon    = "\uf0e0";  // fa-envelope
linkedin_icon = "\uf08c";  // fa-linkedin

contact_size         = 3.2;  // the widest line that fits is about 68 mm at this size
contact_line_spacing = 5.5;
icon_width           = 4.6;  // icon column, as wide as the envelope at contact_size
icon_text_gap        = 1.2;
contact_y            = border_width + 5;  // baseline of the bottom line

// Empty fields are skipped; lines stack upwards from contact_y in this order, top first.
contact_lines = [
    if (email_text != "")    [email_icon, icon_font, email_text],
    if (linkedin_text != "") [linkedin_icon, brand_font, linkedin_text],
];

/* [Back contact QR code] */
back_qr_enabled          = true;
back_qr_size             = 45;
back_qr_error_correction = "M";  // [L, M, Q, H]
back_inlay_depth         = 0.4;  // two 0.2 mm layers
back_qr_shrink           = 0.05; // keeps dark squares from merging
// Solid first layer that the code is seen through; must equal the slicer's initial layer height.
// 0 puts the code flush on the bottom face instead.
back_cover_thickness     = 0.2;

$fn = 64;

base_thickness = card_thickness - border_height;
eps = 0.01;

assert(corner_radius > chamfer, "corner_radius must exceed chamfer");
assert(card_thickness > 2 * chamfer, "card_thickness must exceed 2 * chamfer");
assert(base_thickness >= chamfer, "border_height too large for the bottom chamfer");
assert(border_width > chamfer, "border_width must exceed chamfer");

module rounded_rect(w, h, r) {
    offset(r = r) offset(delta = -r) square([w, h]);
}

module chamfered_slab() {
    hull() {
        translate([chamfer, chamfer, 0])
            linear_extrude(card_thickness)
                rounded_rect(card_width - 2 * chamfer, card_height - 2 * chamfer, corner_radius - chamfer);
        translate([0, 0, chamfer])
            linear_extrude(card_thickness - 2 * chamfer)
                rounded_rect(card_width, card_height, corner_radius);
    }
}

module card_body() {
    difference() {
        chamfered_slab();
        translate([border_width, border_width, base_thickness])
            linear_extrude(card_thickness)
                rounded_rect(card_width - 2 * border_width,
                             card_height - 2 * border_width,
                             max(corner_radius - border_width, 0));
        if (back_qr_enabled && (part != "all" || $preview)) {
            translate([0, 0, back_cover_thickness - eps])
                linear_extrude(back_inlay_depth + eps)
                    back_qr();
            if (back_cover_thickness > 0) below_cover_top();
        }
    }
}

module below_cover_top() {
    translate([-1, -1, -1]) cube([card_width + 2, card_height + 2, back_cover_thickness + 1]);
}

module back_cover() {
    intersection() {
        chamfered_slab();
        below_cover_top();
    }
}

// Mirrored so the code reads correctly when the card is flipped over.
module back_qr() {
    translate([card_width / 2, card_height / 2])
        mirror([1, 0])
            offset(delta = -back_qr_shrink)
                offset(delta = 0.01)
                    qr(vcard, error_correction = back_qr_error_correction,
                       width = back_qr_size, height = back_qr_size, thickness = 0, center = true);
}

module back_inlay() {
    translate([0, 0, back_cover_thickness])
        linear_extrude(back_inlay_depth) back_qr();
}


module card_text() {
    x = border_width + text_margin;
    translate([x, name_y])     text(name_text,     size = name_size,     font = name_font);
    translate([x, title_y])    text(title_text,    size = title_size,    font = body_font);
    for (i = [0 : 1 : len(subtitle_lines) - 1])
        translate([x, subtitle_y - i * subtitle_line_spacing])
            text(subtitle_lines[i], size = subtitle_size, font = body_font);
    n = len(contact_lines);
    for (i = [0 : 1 : n - 1])
        contact_line(contact_lines[i], contact_y + (n - 1 - i) * contact_line_spacing);
}

module contact_line(line, y) {
    x = border_width + text_margin;
    translate([x + icon_width / 2, y])         text(line[0], size = contact_size, font = line[1], halign = "center");
    translate([x + icon_width + icon_text_gap, y]) text(line[2], size = contact_size, font = body_font);
}

module accent() {
    // Single-color export sinks the accent into the card so the union is one manifold solid.
    sink = part == "all" ? eps : 0;
    translate([0, 0, base_thickness - sink])
        linear_extrude(text_height + sink)
            card_text();
}

if (part == "all" || part == "body")   color(body_color)   card_body();
if (part == "all" || part == "accent") color(accent_color) accent();
// The single-color export omits the back code because it would be invisible in one color.
if (back_qr_enabled && (part == "back" || (part == "all" && $preview)))
    color(accent_color) back_inlay();
// Semi-transparent in the preview so the code shows through from below.
if (back_qr_enabled && back_cover_thickness > 0 && (part == "cover" || (part == "all" && $preview)))
    color(cover_color, $preview ? 0.6 : 1) back_cover();
