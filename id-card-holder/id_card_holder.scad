// Slim single-sided portrait ID card holder derived from obj_1_Object_1.stl,
// with a flat backside and debossed logo.
// Front side retains the CR80 card pocket, side retention lips, central
// recessed panel with four tapered spring ribs, bottom thumb notch,
// 45-degree perimeter and window chamfers, and tapered top lanyard loop.

/* [Export] */
// print = upright at origin; reference_pose = matched to obj_1_Object_1.stl bed pose
part = "print"; // [print, reference_pose]
body_color = "darkslategray";
logo_color = "lightslategray"; // Preview contrast color for the debossed logo

/* [Overall Body] */
holder_width = 65.0;
holder_height = 96.0;
holder_radius = 10.0;
front_y = 3.5;               // Front face Y = +3.5
front_recess_y = 0.5;        // Front pocket central recess floor Y = +0.5
back_plate_thickness = 2.0;  // Solid thickness behind front recess (back face Y = -1.5)
back_y = front_recess_y - back_plate_thickness; // -1.5 (total depth = 5.0 mm)
outer_chamfer = 1.5;         // 45-deg chamfer on front and back outer edges

/* [Backside Logo] */
logo_enabled = true;
logo_file = "logo.example.svg"; // SVG file to deboss on the backside (e.g. a *.local.svg)
logo_width = 46.0;              // Rendered logo width on backside (mm)
logo_depth = 0.6;               // Indent depth into the flat backside (mm)
logo_center_z = 54.0;           // Vertical center above bottom thumb notch (mm)
logo_angle = 0;                 // Rotation on the back face (deg)

/* [Lanyard Loop] */
lanyard_top_z = 101.338;
lanyard_hole_bottom_z = 95.838;
lanyard_hole_top_z = 99.838;
lanyard_taper_start_z = 95.838;
// Front face of lanyard loop tapers inward from Y = +3.5 at Z = 95.838
// to Y = +1.954 at Z = 101.338 (slope dY/dZ = -0.28109).
lanyard_taper_slope = (3.5 - 1.954) / (101.338 - 95.838);

/* [Card Pocket] */
pocket_width = 55.4;         // X = [-27.7, +27.7]
pocket_height = 86.4;        // Z = [4.8, 91.2]
pocket_radius = 3.2;
pocket_bottom = (holder_height - pocket_height) / 2; // 4.8
pocket_top = pocket_bottom + pocket_height;          // 91.2
pocket_floor_y = 1.4;        // Plateau & rib top face Y = +1.4
lip_overhang_y = 2.5;        // Inner overhang underside Y = +2.5
lip_groove_y = 2.4;          // Side groove step Y = +2.4
lip_groove_width = 55.0;     // X = [-27.5, +27.5]
lip_chamfer_start_y = 2.7;   // 0.8 mm 45-deg chamfer from Y = +2.7 to +3.5
lip_chamfer = 0.8;
lip_mid_half_width = 23.7;   // Middle retention lip inner X = ±23.7

/* [Central Recess & Spring Ribs] */
recess_width = 55.0;         // X = [-27.5, +27.5]
recess_bottom_z = 10.0;      // Chamfers 0.9 mm inward to Z = 10.9 at Y = 0.5
recess_top_z = 86.0;         // Chamfers 0.9 mm inward to Z = 85.1 at Y = 0.5
rib_width = 1.64;
rib_inner_x = 10.5835;       // Center of inner pair
rib_outer_x = 22.68;         // Center of outer pair
rib_fillet_r = 10.0;
rib_bot_flat_z = 14.021;
rib_bot_ramp_z = 20.0;
rib_top_ramp_z = 32.957;
rib_top_flat_z = 38.775;

/* [Curve Resolution] */
curve_steps = 24;
arc_steps = 20;
eps = 0.02;
cut_pad = 1.0;               // Extra overshoot past outer faces for clean F5 OpenCSG preview

// --- Math & Spline Helpers ---

function bezier5(p0, p1, p2, p3, p4, p5, t) =
    let(u = 1 - t)
    u*u*u*u*u * p0 +
    5*u*u*u*u*t * p1 +
    10*u*u*u*t*t * p2 +
    10*u*u*t*t*t * p3 +
    5*u*t*t*t*t * p4 +
    t*t*t*t*t * p5;

function sample_bezier5(p0, p1, p2, p3, p4, p5, steps, include_first=true, include_last=true) = [
    for (i = [include_first ? 0 : 1 : include_last ? steps : steps - 1])
        bezier5(p0, p1, p2, p3, p4, p5, i / steps)
];

function sample_arc(cx, cy, r, a0, a1, steps, include_first=true, include_last=true) = [
    for (i = [include_first ? 0 : 1 : include_last ? steps : steps - 1])
        let(a = a0 + (a1 - a0) * (i / steps))
        [cx + r * cos(a), cy + r * sin(a)]
];

function reverse_pts(pts) = [for (i = [len(pts) - 1 : -1 : 0]) pts[i]];
function mirror_x_pts(pts) = [for (p = pts) [-p[0], p[1]]];
function mirror_z_pts(pts, z_mid) = [for (p = pts) [p[0], 2 * z_mid - p[1]]];

// Deduplicate consecutive near-identical 2D points in a closed polygon.
function clean_poly(pts, tol=1e-4) = [
    for (i = [0 : len(pts) - 1])
        let(prev = pts[(i - 1 + len(pts)) % len(pts)],
            cur = pts[i],
            d = norm([cur[0] - prev[0], cur[1] - prev[1]]))
        if (d > tol) cur
];

// Compute unit inward (sign=+1) or outward (sign=-1) offset of a CCW 2D polygon.
function offset_smooth_poly(pts, delta) =
    let(n = len(pts))
    [
        for (i = [0 : n - 1])
            let(
                p_prev = pts[(i - 1 + n) % n],
                p_next = pts[(i + 1) % n],
                t = [p_next[0] - p_prev[0], p_next[1] - p_prev[1]],
                tl = norm(t),
                // For a CCW polygon in XZ, inward normal is (-tz, tx) / |t|
                in_n = [-t[1] / tl, t[0] / tl]
            )
            [pts[i][0] + delta * in_n[0], pts[i][1] + delta * in_n[1]]
    ];

// --- 2D Profiles (in XZ plane, later mapped to 3D [X, Y, Z]) ---

// Half outer silhouette from X=0 at top (Z=101.338) clockwise/CCW around X>=0
// to X=0 at notch top (Z=15.0). Returned points trace X>=0 from Z=15 up to Z=101.338 (CCW).
function outer_right_half_pts() =
    let(
        // Bottom thumb notch: (0, 15) -> (9.85, 7.5) -> (17.0, 0)
        notch_top = sample_bezier5(
            [2.48, 15.0], [5.475, 15.0], [8.48, 15.0],
            [9.85, 13.5], [9.85, 9.9], [9.85, 7.5],
            curve_steps, include_first=true, include_last=true
        ),
        notch_bot = sample_bezier5(
            [9.855, 7.49], [9.855, 4.875], [9.855, 1.475],
            [11.0, 0.0], [13.99, 0.0], [16.995, 0.0],
            curve_steps, include_first=false, include_last=true
        ),
        // Bottom-right corner R=10 centered at (22.5, 10.0)
        br_arc = sample_arc(
            holder_width/2 - holder_radius, holder_radius, holder_radius,
            -90, 0, arc_steps, include_first=true, include_last=true
        ),
        // Top-right corner R=10 centered at (22.5, 86.0)
        tr_arc = sample_arc(
            holder_width/2 - holder_radius, holder_height - holder_radius, holder_radius,
            0, 90, arc_steps, include_first=true, include_last=true
        ),
        // Lanyard outer neck & top: (12.0, 96.0) -> (7.45, 98.74) -> (2.995, 101.338)
        ang = 54.67,
        dx = cos(ang),
        dz = -sin(ang),
        lan_bot = sample_bezier5(
            [12.0, 96.0], [10.795, 96.0], [9.505, 96.0],
            [7.45 + 2.105*dx, 98.74 + 2.105*dz],
            [7.45 + 1.0525*dx, 98.74 + 1.0525*dz],
            [7.45, 98.74],
            curve_steps, include_first=true, include_last=true
        ),
        lan_top = sample_bezier5(
            [7.45, 98.74],
            [7.45 - 0.75*dx, 98.74 - 0.75*dz],
            [7.45 - 1.5*dx, 98.74 - 1.5*dz],
            [2.995 + 2.5, lanyard_top_z],
            [2.995 + 1.6, lanyard_top_z],
            [2.995, lanyard_top_z],
            curve_steps, include_first=false, include_last=true
        )
    )
    concat(
        [[0, 15.0]],
        notch_top,
        notch_bot,
        br_arc,
        tr_arc,
        lan_bot,
        lan_top
    );

function outer_profile_pts() =
    let(
        rh = outer_right_half_pts(),
        lh = reverse_pts(mirror_x_pts(rh))
    )
    clean_poly(concat(rh, lh));

// Lanyard inner hole (CCW in XZ).
function lanyard_hole_pts() =
    let(
        // Right half lines & fillets:
        // Bottom flat: (0, 95.838) -> (6.609, 95.838)
        // Bottom-right corner R=0.20 centered at (6.609, 96.0381) from -90 to 36.77 deg
        ang_side = atan2(1.33779, 1.0), // 53.22 deg from X; normal angle = 90 - 53.22 = 36.78 deg
        br_c = sample_arc(6.6090, 96.0381, 0.200, -90, 36.78, 8, true, true),
        // Top-right corner R=1.0063 centered at (4.7420, 97.1881) from 36.78 to 71.48 deg
        ang_top = atan2(1.0, 0.33501), // 71.48 deg
        tr_c = sample_arc(4.7420, 97.1881, 1.0063, 36.78, ang_top, 12, true, true),
        rh = concat([[0, lanyard_hole_bottom_z]], br_c, tr_c, [[0, lanyard_hole_top_z]]),
        lh = reverse_pts(mirror_x_pts(rh))
    )
    clean_poly(concat(rh, lh));

// Full pocket base rounded rectangle (55.4 x 86.4, R=3.2, CCW in XZ).
function pocket_base_pts() =
    let(
        x_r = pocket_width / 2,
        c_x = x_r - pocket_radius,
        c_zb = pocket_bottom + pocket_radius,
        c_zt = pocket_top - pocket_radius
    )
    clean_poly(concat(
        sample_arc( c_x, c_zb, pocket_radius, -90,   0, arc_steps, true, true),
        sample_arc( c_x, c_zt, pocket_radius,   0,  90, arc_steps, true, true),
        sample_arc(-c_x, c_zt, pocket_radius,  90, 180, arc_steps, true, true),
        sample_arc(-c_x, c_zb, pocket_radius, 180, 270, arc_steps, true, true)
    ));

// Side S-curve from (27.7, 20.5) up to (23.7, 35.64) (CCW right side).
function side_scurve_lower_pts() =
    let(
        z0 = 20.5,
        z_mid = 28.07,
        ang = 49.975,
        dx = sin(ang),
        dz = -cos(ang),
        c1 = sample_bezier5(
            [27.7, z0],
            [27.7, z0 + 1.53],
            [27.7, z0 + 3.925],
            [25.7 + 2.4*dx, z_mid + 2.4*dz],
            [25.7 + 1.4*dx, z_mid + 1.4*dz],
            [25.7, z_mid],
            curve_steps, include_first=true, include_last=true
        ),
        c2 = reverse_pts([for (p = c1) [2*25.7 - p[0], 2*z_mid - p[1]]])
    )
    concat(c1, [for (i = [1 : len(c2) - 1]) c2[i]]);

// Front pocket window opening (CCW in XZ, includes side S-curve retention lips).
function front_opening_pts() =
    let(
        x_r = pocket_width / 2,
        c_x = x_r - pocket_radius,
        c_zb = pocket_bottom + pocket_radius,
        c_zt = pocket_top - pocket_radius,
        sc_lo = side_scurve_lower_pts(),
        sc_hi = reverse_pts(mirror_z_pts(sc_lo, holder_height / 2)),
        rh = concat(
            sample_arc(c_x, c_zb, pocket_radius, -90, 0, arc_steps, true, true),
            sc_lo,
            sc_hi,
            sample_arc(c_x, c_zt, pocket_radius, 0, 90, arc_steps, true, true)
        ),
        lh = reverse_pts(mirror_x_pts(rh))
    )
    clean_poly(concat(rh, lh));

// --- 3D Polyhedron Builders (X, Y, Z) ---

// Builds a closed 3D solid from a CCW 2D XZ polygon `p0` at Y=`y0`
// lofted linearly to `p1` at Y=`y1` (valid whether y1 > y0 or y1 < y0).
module loft_xz_poly(p0, y0, p1, y1) {
    n = len(p0);
    assert(len(p1) == n, "loft_xz_poly requires equal point counts");
    pts = concat(
        [for (p = p0) [p[0], y0, p[1]]],
        [for (p = p1) [p[0], y1, p[1]]]
    );
    // Side quads split into triangles; ensure outward winding regardless of y1 > y0
    flip = (y1 > y0);
    side_tris = [
        for (i = [0 : n - 1])
            let(j = (i + 1) % n)
            each (flip
                ? [[i, j, n + j], [i, n + j, n + i]]
                : [[i, n + j, j], [i, n + i, n + j]])
    ];
    cap0 = [flip ? [for (i = [n - 1 : -1 : 0]) i] : [for (i = [0 : n - 1]) i]];
    cap1 = [flip ? [for (i = [0 : n - 1]) n + i] : [for (i = [n - 1 : -1 : 0]) n + i]];
    polyhedron(points = pts, faces = concat(side_tris, cap0, cap1), convexity = 6);
}

// Extrudes a 2D XZ polygon along Y from y_min to y_max.
module extrude_xz(pts, y_min, y_max) {
    translate([0, y_max, 0])
        rotate([90, 0, 0])
            linear_extrude(height = y_max - y_min)
                polygon(pts);
}

// Outer shell with 1.5 mm 45-deg front and back chamfers, front lanyard taper, and lanyard hole.
module outer_shell() {
    outer_pts = outer_profile_pts();
    outer_in  = offset_smooth_poly(outer_pts, outer_chamfer);
    y_front_core = front_y - outer_chamfer; // +2.0
    y_back_core  = back_y + outer_chamfer;  //  0.0 (with back_plate_thickness = 2.0)

    // Taper wedge height above lanyard_taper_start_z (front +Y side only so backside stays flat)
    z_cut_top = lanyard_top_z + 1.0;
    y_top_cut = front_y - lanyard_taper_slope * (z_cut_top - lanyard_taper_start_z);

    difference() {
        union() {
            // Core vertical-walled slab Y = [y_back_core, y_front_core]
            if (y_front_core > y_back_core + 1e-4)
                extrude_xz(outer_pts, y_back_core, y_front_core);
            // Front 45-deg chamfer Y = [y_front_core, front_y]
            loft_xz_poly(outer_pts, y_front_core, outer_in, front_y);
            // Back 45-deg chamfer Y = [y_back_core, back_y]
            loft_xz_poly(outer_pts, y_back_core, outer_in, back_y);
        }

        // Lanyard loop front (+Y) inward taper above Z = 95.838
        translate([-holder_width, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(height = 2 * holder_width)
                    polygon([
                        [front_y + eps, lanyard_taper_start_z],
                        [front_y + eps, z_cut_top],
                        [y_top_cut, z_cut_top]
                    ]);

        // Lanyard through-hole (vertical walls in Y)
        extrude_xz(lanyard_hole_pts(), back_y - cut_pad, front_y + cut_pad);
    }
}

// Pocket + lip + central recess cutter for the front (+Y) card slot.
module side_pocket_cutout() {
    p_base = pocket_base_pts();
    p_open = front_opening_pts();
    p_open_out = offset_smooth_poly(p_open, -(lip_chamfer + cut_pad));

    // (a) Main pocket cavity Y = [1.4, 2.4 + eps]
    extrude_xz(p_base, pocket_floor_y, lip_groove_y + eps);

    // (b) Step at Y = [2.4, 2.5 + eps]: 55.0 mm wide lip overhang + open ends
    intersection() {
        extrude_xz(p_base, lip_groove_y - eps, lip_overhang_y + eps);
        translate([-lip_groove_width / 2, lip_groove_y - eps, 0])
            cube([lip_groove_width, (lip_overhang_y - lip_groove_y) + 2 * eps, holder_height]);
    }
    extrude_xz(p_open, lip_groove_y - eps, lip_overhang_y + eps);

    // (c) Front lip opening Y = [2.5, 2.7]
    extrude_xz(p_open, lip_overhang_y - eps, lip_chamfer_start_y);

    // (d) Front lip 0.8 mm 45-deg chamfer Y = [2.7, 3.5 + cut_pad]
    loft_xz_poly(p_open, lip_chamfer_start_y, p_open_out, front_y + cut_pad);

    // (e) Central deep recess Y = [0.5, 1.4 + eps], X = [-27.5, +27.5],
    //     Z = [10.0, 86.0] at Y=1.4 chamfered 0.9 mm inward to Z = [10.9, 85.1] at Y=0.5.
    rec_chamfer = pocket_floor_y - front_recess_y; // 0.9
    translate([-recess_width / 2, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = recess_width)
                polygon([
                    [front_recess_y, recess_bottom_z + rec_chamfer],
                    [pocket_floor_y + eps, recess_bottom_z - eps],
                    [pocket_floor_y + eps, recess_top_z + eps],
                    [front_recess_y, recess_top_z - rec_chamfer]
                ]);
}

// Single spring rib pair (bottom + top) in YZ extruded along X at centered x_pos.
module spring_rib(x_pos) {
    y_base = front_recess_y - eps;
    y_top = pocket_floor_y; // 1.4
    ang = 10.39;
    yc = y_top - rib_fillet_r;

    bot_fillet = sample_arc(yc, rib_bot_flat_z, rib_fillet_r, 0, ang, 16, true, true);
    top_fillet = sample_arc(yc, rib_top_flat_z, rib_fillet_r, -ang, 0, 16, true, true);

    bot_yz = concat(
        [[y_base, pocket_bottom], [y_top, pocket_bottom]],
        bot_fillet,
        [[front_recess_y, rib_bot_ramp_z], [y_base, rib_bot_ramp_z]]
    );
    top_yz = concat(
        [[y_base, rib_top_ramp_z], [front_recess_y, rib_top_ramp_z]],
        top_fillet,
        [[y_top, recess_top_z], [y_base, recess_top_z]]
    );

    translate([x_pos - rib_width / 2, 0, 0])
        rotate([90, 0, 90])
            linear_extrude(height = rib_width) {
                polygon(bot_yz);
                polygon(top_yz);
            }
}

module side_ribs() {
    for (sx = [-1, 1]) {
        spring_rib(sx * rib_inner_x);
        spring_rib(sx * rib_outer_x);
    }
}

// Debossed logo cutter on the flat backside (-Y).
module back_logo_cutout() {
    color(logo_color)
        translate([0, back_y + logo_depth, logo_center_z])
            rotate([90, 0, 0])
                linear_extrude(height = logo_depth + cut_pad, convexity = 10)
                    rotate([0, 0, logo_angle])
                        resize([logo_width, 0], auto = true)
                            import(logo_file, center = true);
}

module id_card_holder() {
    outer_pts = outer_profile_pts();
    difference() {
        color(body_color)
            union() {
                difference() {
                    outer_shell();
                    // Single card pocket on the front (+Y) side
                    side_pocket_cutout();
                }

                // Add spring ribs inside the front pocket, trimmed to the outer shell
                intersection() {
                    extrude_xz(outer_pts, front_recess_y - eps, pocket_floor_y + eps);
                    side_ribs();
                }
            }

        if (logo_enabled && logo_depth > 0)
            back_logo_cutout();
    }
}

if (part == "print") {
    id_card_holder();
} else if (part == "reference_pose") {
    translate([128, 128, 0])
        rotate([0, 0, 20])
            id_card_holder();
}
