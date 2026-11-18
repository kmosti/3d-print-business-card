# ID card holder

Parametric OpenSCAD model for a slim single-sided portrait CR80 ID card holder with a flat backside, debossed logo, side retention lips, spring ribs, bottom thumb notch, and tapered top lanyard loop.

## Files

| Path               | Description                                              |
| ------------------ | -------------------------------------------------------- |
| `id_card_holder.scad` | Parametric ID card holder OpenSCAD model.             |
| `logo.example.svg` | Generic open-source SVG logo debossed by default.        |

Generated `.stl` files and custom `*.local.svg` / `*.private.svg` files are ignored by git.

## Export STL files

Run from inside `id-card-holder/`:

```sh
# Default generic logo
openscad -o id_card_holder.stl id_card_holder.scad

# Custom local logo SVG
openscad -D 'logo_file="my_logo.local.svg"' -o id_card_holder.stl id_card_holder.scad
```

