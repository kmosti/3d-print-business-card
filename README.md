# 3D-printed business card

This project contains a parametric OpenSCAD model of an 85 x 55 mm business card. The card has a raised border, raised text, and a scannable QR code on the front. With an AMS, you can also print a contact QR code into the back of the card. Scanning it offers to save the contact on the phone. You can print the card in one color or two colors.

## Files

| Path                       | Description                                                                                                 |
| -------------------------- | ----------------------------------------------------------------------------------------------------------- |
| `business_card.scad`       | OpenSCAD model. Layout and print parameters are at the top of the file.                                     |
| `personal.example.scad`    | Fictional personal details. Copy it to `personal.scad`.                                                     |
| `personal.scad`            | Your personal details: name, text lines, phone, email, and QR content. Ignored by git.                      |
| `fonts/`                   | Inter Bold and Inter SemiBold text fonts, and the Font Awesome 6 Free Solid icon font, loaded by the model. |
| `lib/qr.scad`              | [scadqr](https://github.com/xypwn/scadqr) library that generates the QR code.                               |
| `business_card.stl`        | Single-color export.                                                                                        |
| `business_card_body.stl`   | Multi-color export: card body.                                                                              |
| `business_card_accent.stl` | Multi-color export: raised text and front QR code.                                                          |
| `business_card_back.stl`   | Multi-color export: contact QR code inlaid into the back.                                                   |

The STL files are generated, so `.gitignore` excludes them. To create them, see [Export STL files](#export-stl-files).

## Model geometry

| Feature                    | Height above print bed            |
| -------------------------- | --------------------------------- |
| Back QR inlay              | 0 to 0.4 mm, flush with the back  |
| Card surface (inner field) | 1.2 mm                            |
| Raised text and QR code    | 1.8 mm (0.6 mm above the surface) |
| Raised border              | 2.0 mm (0.8 mm above the surface) |

The outer edges have a 0.4 mm chamfer on the top and bottom. The model prints face up without supports.

## Customize the card

Personal details live in `personal.scad`, which `.gitignore` excludes so that they never get committed. The model loads the fictional values from `personal.example.scad` first, and then overrides them with the values in `personal.scad`.

1. Copy the example file:

   ```sh
   cp personal.example.scad personal.scad
   ```

1. Edit `personal.scad` with your details.
1. Open `business_card.scad` in OpenSCAD 2021.01 or later.
1. Optional: edit the layout and print parameters at the top of `business_card.scad`.
1. Press **F5** to preview the card in color.

If `personal.scad` doesn't exist, OpenSCAD shows the warning `Can't open include file 'personal.scad'` and renders the card with the fictional details.

If you add a personal-details variable, add it to both files, with a fictional value in `personal.example.scad`.

Keep `qr_message` short. Longer messages produce a denser QR code with smaller squares, which are harder to print and scan. Set `qr_message = ""` to print an empty placeholder frame instead of a QR code.

If you change text sizes, check the preview to make sure that no text overlaps the border or the QR code.

To show the subtitle on several lines, set `subtitle_text` to a list of strings, for example `["First line", "Second line"]`. There is room for two subtitle lines above the front QR code.

The phone and email lines sit to the left of the QR code. Keep a gap of at least 3 mm between the end of the email line and the QR code, because QR scanners need a blank margin around the code. If you use a longer email address, reduce `contact_size`.

The phone and email icons come from the Font Awesome icon font, because OpenSCAD can't turn color emoji into 3D shapes. To use a different icon, set `phone_icon` or `email_icon` to the icon's Unicode code point from the [Font Awesome icon gallery](https://fontawesome.com/search?ic=free&s=solid), for example `"\uf3cd"` for a mobile phone.

### Back contact QR code

The back QR code contains a vCard 3.0 contact card. iPhone and Android cameras recognize it and offer to add the contact. The card uses these parameters from `personal.scad`:

- `vcard_first_name` and `vcard_last_name`.
- `phone_text` and `email_text`, the same values that the front of the card shows.
- Optional `vcard_org`, `vcard_title`, and `vcard_url`. Leave a field empty to omit it.

Each extra field makes the code denser. With name, phone, and email, the 45 mm code has 49 x 49 squares of about 0.9 mm each. Keep the squares at 0.8 mm or larger: square size is `back_qr_size` divided by the number of squares per side.

The code is mirrored in the model so that it reads correctly from the back. The `back_qr_shrink` parameter makes the dark squares slightly smaller to compensate for the squashed first layer. Set `back_qr_enabled = false` to remove the back code.

The back code is part of the multi-color export only.

## Export STL files

Run these commands from the project folder:

```sh
# Single color
openscad -o business_card.stl business_card.scad

# Multi-color (AMS)
openscad -D 'part="body"'   -o business_card_body.stl   business_card.scad
openscad -D 'part="accent"' -o business_card_accent.stl business_card.scad
openscad -D 'part="back"'   -o business_card_back.stl   business_card.scad
```

## Print with Bambu Studio

Choose one of the following methods:

- **Method A:** two colors with an AMS (Automatic Material System). The printer switches filament automatically. This is the only method that prints the back contact QR code.
- **Method B:** two colors without an AMS. You swap the filament manually during a pause.
- **Method C:** one color.

For two-color prints, use a light filament for the card body and a dark filament for the text. Most phone cameras can't scan a light QR code on a dark background.

### Recommended settings

Start from the **0.20mm Standard** process profile for your printer and a 0.4 mm nozzle. With 0.20 mm layers, every height in the model falls exactly on a layer boundary.

| Setting      | Value                                                                        |
| ------------ | ---------------------------------------------------------------------------- |
| Filament     | PLA                                                                          |
| Layer height | 0.20 mm                                                                      |
| Supports     | Off                                                                          |
| Brim         | None (enable it only if the corners lift)                                    |
| Build plate  | Textured PEI (recommended): its matte back reduces glare on the back QR code |

### Method A: two colors with an AMS

1. Export `business_card_body.stl`, `business_card_accent.stl`, and `business_card_back.stl`.
1. Load the light filament and the dark filament into the AMS.
1. In Bambu Studio, select **File** > **Import** > **Import 3MF/STL/STEP/SVG/OBJ/AMF**.
1. Select all three STL files and click **Open**.
1. When Bambu Studio asks whether to load the files as a single object with multiple parts, click **Yes**. The parts stay aligned with the card.
1. In the **Prepare** tab, sync the filament list with the AMS so that the slots match the loaded filaments.
1. In the object list, expand the object to show its three parts.
1. Assign filaments:
   1. Set `business_card_body` to the light filament.
   1. Set `business_card_accent` to the dark filament.
   1. Set `business_card_back` to the dark filament.
1. Optional: to print several cards, right-click the object, select **Clone**, and enter the number of copies.
1. Click **Slice plate**.
1. In the **Preview** tab, check the colors:
   1. Drag the layer slider to the first layer and check that the back QR code shows the dark color.
   1. Drag the slider to the top and check that the text and front QR code show the dark color.
1. Click **Print plate**.

The printer changes filament on the first two layers for the back code and on the top layers for the text. Each print has few filament changes, so the prime tower and filament waste stay small.

### Method B: two colors without an AMS

This method prints the single-color STL and pauses at the card surface so you can load the dark filament. Everything above the pause prints in the dark color, including the top of the border.

1. Export `business_card.stl`.
1. In Bambu Studio, select **File** > **Import** > **Import 3MF/STL/STEP/SVG/OBJ/AMF** and open `business_card.stl`.
1. Click **Slice plate**.
1. In the **Preview** tab, drag the layer slider on the right to the layer at **1.40 mm**. This is the first layer above the card surface.
1. Right-click the **+** icon on the slider and select **Add Pause**.
1. Slice again and confirm that the pause marker is at 1.40 mm.
1. Load the light filament and click **Print plate**.
1. When the printer pauses, use the printer screen to unload the light filament and load the dark filament.
1. Resume the print.

### Method C: one color

1. Export `business_card.stl`.
1. In Bambu Studio, select **File** > **Import** > **Import 3MF/STL/STEP/SVG/OBJ/AMF** and open `business_card.stl`.
1. Click **Slice plate**, and then click **Print plate**.

The text and QR code are raised, so they stay readable in one color. The QR code is usually not scannable without contrast.

## Test the QR codes

After printing, scan both QR codes with a phone camera in good light. The back code should offer to add the contact. If a code doesn't scan, try these fixes:

- Use filaments with stronger contrast, such as white and black.
- Shorten `qr_message`, or remove optional vCard fields, so that the code uses fewer, larger squares.
- Set the error correction parameter to `"H"` if the content is short enough to keep the squares large.
- Remove any stringing between the QR squares.
- If dark squares on the back merge, increase `back_qr_shrink` to 0.1.

## Licenses

This project is licensed under the MIT license. See `LICENSE`.

The project includes these third-party files under their own licenses:

- Inter font: SIL Open Font License 1.1. See `fonts/Inter-LICENSE.txt`.
- Font Awesome Free font: SIL Open Font License 1.1. See `fonts/FontAwesome-LICENSE.txt`.
- scadqr library: MIT license. See the header in `lib/qr.scad`.
