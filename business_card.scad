// 3D-printable business card.
// Print face up, no supports. Overall thickness is card_thickness at the border;
// the inner field is thinner (card_thickness - border_height) to save material.

use <fonts/Inter-Bold.ttf>
use <fonts/Inter-SemiBold.ttf>
use <fonts/fa-solid-900.ttf>
use <lib/qr.scad>
include <contact.scad>

/* [Export] */
// all = single-color STL; body / accent / back = separate STLs for a multi-color print
part = "all"; // [all, body, accent, back]
body_color   = "white";  // keep light: scanners need dark QR modules on a light background
accent_color = "black";

/* [Card] */
card_width     = 85;
card_height    = 55;
card_thickness = 2;     // total thickness at the raised border
corner_radius  = 2;
chamfer        = 0.4;   // 45-degree chamfer on top and bottom outer edges

/* [Relief] */
border_height = 0.8;    // border rises this much above the card surface
border_width  = 2;
text_height   = 0.6;    // text and QR frame rise this much above the card surface

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
subtitle_lines = is_list(subtitle_text) ? subtitle_text : [subtitle_text];

/* [QR code] */
qr_error_correction = "M";  // [L, M, Q, H]
qr_area_size        = 20;
qr_margin           = 3;    // light gap to the border; acts as the QR quiet zone
qr_frame_width      = 0.8;

/* [Contact] */
// Color emoji can't be extruded, so the icons are Font Awesome glyphs.
icon_font  = "Font Awesome 6 Free:style=Solid";
phone_icon = "\uf095";  // fa-phone
email_icon = "\uf0e0";  // fa-envelope

contact_size = 2.5;     // keeps the email line clear of the QR quiet zone
icon_gap     = 4;       // distance from icon start to text start
email_y      = border_width + qr_margin + 1;  // text baselines
phone_y      = email_y + 5;

/* [Back contact QR code] */
back_qr_enabled          = true;
back_qr_size             = 45;
back_qr_error_correction = "M";  // [L, M, Q, H]
back_inlay_depth         = 0.4;  // two 0.2 mm layers, flush with the bottom face
back_qr_shrink           = 0.05; // offsets first-layer squish so dark squares don't merge

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
        if (back_qr_enabled && (part != "all" || $preview))
            translate([0, 0, -eps])
                linear_extrude(back_inlay_depth + eps)
                    back_qr();
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
    linear_extrude(back_inlay_depth) back_qr();
}


module card_text() {
    x = border_width + text_margin;
    translate([x, name_y])     text(name_text,     size = name_size,     font = name_font);
    translate([x, title_y])    text(title_text,    size = title_size,    font = body_font);
    for (i = [0 : len(subtitle_lines) - 1])
        translate([x, subtitle_y - i * subtitle_line_spacing])
            text(subtitle_lines[i], size = subtitle_size, font = body_font);
    contact_line(phone_icon, phone_text, phone_y);
    contact_line(email_icon, email_text, email_y);
}

module contact_line(icon, label, y) {
    x = border_width + text_margin;
    translate([x, y])            text(icon,  size = contact_size, font = icon_font);
    translate([x + icon_gap, y]) text(label, size = contact_size, font = body_font);
}

module qr_area() {
    translate([card_width - border_width - qr_margin - qr_area_size, border_width + qr_margin])
        if (qr_message == "") {
            difference() {
                square(qr_area_size);
                translate([qr_frame_width, qr_frame_width])
                    square(qr_area_size - 2 * qr_frame_width);
            }
        } else {
            // Grow modules slightly so diagonal neighbours fuse into one manifold solid.
            offset(delta = 0.01)
                qr(qr_message, error_correction = qr_error_correction,
                   width = qr_area_size, height = qr_area_size, thickness = 0);
        }
}

module accent() {
    // Single-color export sinks the accent into the card so the union is one manifold solid.
    sink = part == "all" ? eps : 0;
    translate([0, 0, base_thickness - sink])
        linear_extrude(text_height + sink) {
            card_text();
            qr_area();
        }
}

if (part == "all" || part == "body")   color(body_color)   card_body();
if (part == "all" || part == "accent") color(accent_color) accent();
// The single-color export omits the back code because it would be invisible in one color.
if (back_qr_enabled && (part == "back" || (part == "all" && $preview)))
    color(accent_color) back_inlay();
