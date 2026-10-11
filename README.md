# 3D-printed business card

Parametric OpenSCAD models for an 85 x 55 mm business card, a desk stand, and a carry case. The card has raised text and an optional contact QR code on the back. Scanning the code offers to save the contact on the phone.

## Files

| Path                    | Description                                                    |
| ----------------------- | -------------------------------------------------------------- |
| `business_card.scad`    | Card model.                                                    |
| `card_holder.scad`      | Desk stand for a stack of cards.                               |
| `card_case.scad`        | Carry case with a snap-on lid.                                 |
| `contact.scad`          | Loads the personal details and builds the vCard for QR codes.  |
| `personal.example.scad` | Fictional personal details.                                    |
| `personal.scad`         | Your personal details. Ignored by git.                         |
| `fonts/`                | Inter text fonts and Font Awesome icon fonts.                  |
| `lib/qr.scad`           | [scadqr](https://github.com/xypwn/scadqr) QR code library.     |

Generated STL files are ignored by git.

## Set up

1. Install OpenSCAD 2021.01 or later.
1. Copy the example details and edit the copy:

   ```sh
   cp personal.example.scad personal.scad
   ```

1. Open `business_card.scad` and press **F5** to preview.

Without `personal.scad`, OpenSCAD warns `Can't open include file` and uses the fictional details. When you add a personal-details variable, add it to both files.

## Customize the card

Layout and print parameters are at the top of each `.scad` file.

- To hide a text line, set its field to `""`.
- To split the subtitle over several lines, use a list: `subtitle_text = ["Line 1", "Line 2"];`.
- At `contact_size = 3.2`, a contact line fits up to about 68 mm. For longer lines, reduce `contact_size`.
- The icons are [Font Awesome](https://fontawesome.com/search?ic=free) glyphs, because OpenSCAD can't extrude color emoji. To change an icon, set `email_icon` or `linkedin_icon` to a Unicode code point, such as `"\uf0e1"`.

### Back QR code

The back QR code holds a vCard with `vcard_first_name`, `vcard_last_name`, `email_text`, and the optional `vcard_org`, `vcard_title`, and `vcard_url`.

Each field makes the code denser. Keep each square at 0.8 mm or larger; square size is `back_qr_size` divided by the squares per side. With a name and email, the 45 mm code has 41 x 41 squares of 1.1 mm.

The code prints behind a solid first layer, the cover. The cover gives the print a clean first layer and hides color specks.

- Set `back_cover_thickness` to the slicer's initial layer height. The default is 0.2 mm.
- Print the cover in translucent PLA for the best contrast, or in white PLA.
- To print the code on the bottom face without a cover, set `back_cover_thickness = 0`.
- To remove the code, set `back_qr_enabled = false`.

## Export STL files

```sh
# Card, single color
openscad -o business_card.stl business_card.scad

# Card, multi-color parts
openscad -D 'part="body"'   -o business_card_body.stl   business_card.scad
openscad -D 'part="accent"' -o business_card_accent.stl business_card.scad
openscad -D 'part="back"'   -o business_card_back.stl   business_card.scad
openscad -D 'part="cover"'  -o business_card_cover.stl  business_card.scad

# Desk stand
openscad -o card_holder.stl card_holder.scad

# Carry case, single color
openscad -o card_case.stl card_case.scad

# Carry case, rims only, to test the lid fit
openscad -D 'part="fit_test"' -o card_case_fit_test.stl card_case.scad

# Carry case, multi-color parts
openscad -D 'part="body"'  -o card_case_body.stl  card_case.scad
openscad -D 'part="inlay"' -o card_case_inlay.stl card_case.scad
openscad -D 'part="cover"' -o card_case_cover.stl card_case.scad
```

## Print with Bambu Studio

### Settings

Start from the **0.20mm Standard @BBL** profile with a 0.4 mm nozzle, and change these settings:

| Setting                    | Value       | Location                     |
| -------------------------- | ----------- | ---------------------------- |
| Nozzle temperature         | 215–220 °C  | Filament                     |
| Bed temperature            | 55–60 °C    | Filament, Textured PEI Plate |
| Layer height               | 0.2 mm      | Process > Quality            |
| Initial layer height       | 0.2 mm      | Process > Quality            |
| Elephant foot compensation | 0.2 mm      | Process > Quality            |
| Initial layer speed        | 30 mm/s     | Process > Speed              |
| Initial layer infill speed | 40 mm/s     | Process > Speed              |
| Supports                   | Off         | Process > Support            |
| Brim type                  | No brim     | Process > Others             |
| Prime tower                | On          | Process > Others             |
| Flushing volume multiplier | 1.5         | Prepare > Flushing volumes   |

- A bed above 60 °C softens PLA and causes elephant foot, a lip around the bottom edge.
- For adhesion, wash the plate with dish soap and water. If corners still lift, use glue stick or a **Mouse ear** brim.
- The initial layer height must equal `back_cover_thickness` and the case's `cover_thickness`.
- Use PLA for all parts. PETG bonds poorly to PLA.

### Multi-color print (AMS)

1. Export the multi-color parts.
1. In Bambu Studio, import all parts of one model together.
1. When asked to load the files as a single object with multiple parts, click **Yes**.
1. Assign filaments:

   | Part                                                            | Filament             |
   | --------------------------------------------------------------- | -------------------- |
   | `business_card_body`, `card_case_body`                          | Light                |
   | `business_card_accent`, `business_card_back`, `card_case_inlay` | Dark                 |
   | `business_card_cover`, `card_case_cover`                        | Translucent or light |

1. Slice and check the layers in the **Preview** tab.
1. Print.

QR codes need dark squares on a light background. To print several cards with fewer filament changes per card, right-click the card and select **Clone**.

### Two colors without an AMS

1. Slice `business_card.stl`.
1. In the **Preview** tab, right-click the layer slider at 1.40 mm and select **Add Pause**.
1. When the printer pauses, change to the dark filament.

The text and the top of the border print dark. This method can't print the back QR code.

### One color

Print `business_card.stl`, `card_holder.stl`, or `card_case.stl` with the settings above.

## Test the QR code

Scan the code with a phone camera in good light. If it doesn't scan:

- Use higher-contrast filaments.
- Remove optional vCard fields to get larger squares.
- If dark squares merge, increase `back_qr_shrink` to 0.1.

## Desk stand

The stand holds 10 cards on their long edge, tilted back 15°. A 5 mm front lip keeps the front card readable.

- `card_count`: number of cards.
- `width_clearance`, `stack_clearance`: fit of the cards.
- `card_width`, `card_height`, `card_thickness`: must match `business_card.scad`.

## Carry case

The case holds 10 cards in a 90 x 60 x 23.4 mm box. The lid slides over a lip on the base and clicks into place: a bump on each long side of the lip snaps into a groove in the lid. The cards stick out of the base, so you can grip them when the lid is off.

In multi-color prints, the lid shows the name and the base shows the back QR code. Like the card's back QR code, both inlays print behind a cover layer, set by `cover_thickness`.

- `card_count`: number of cards.
- `detent_height`: how far each bump sticks out. The default is 0.4 mm. Raise it for a firmer click, or lower it if the lid is hard to close.
- `fit_clearance`: gap between the lip and the lid, per side. The default is 0.2 mm. Keep it below `detent_height`.
- `base_fraction`: share of the inner height in the base.
- `name_size`, `qr_size`: inlay sizes.
- `part = "assembled"`: previews the closed case.

To tune the click, print `card_case_fit_test.stl`. It contains only the rims of the base and the lid, and prints in a few minutes. Adjust `detent_height` in steps of 0.05 mm.

## Licenses

This project uses the MIT license. See `LICENSE`. Third-party files:

- Inter: SIL Open Font License 1.1. See `fonts/Inter-LICENSE.txt`.
- Font Awesome Free: SIL Open Font License 1.1. See `fonts/FontAwesome-LICENSE.txt`.
- scadqr: MIT license. See `lib/qr.scad`.
