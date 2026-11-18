# 3D Print Projects

A monorepo of parametric OpenSCAD and 3D-printable projects.

## Projects

| Project                                | Description                                                                   |
| -------------------------------------- | ----------------------------------------------------------------------------- |
| [business-card/](business-card/README.md) | Parametric business card with vCard QR code, desk stand, and carry case.      |
| [secret-door/](secret-door/README.md)  | Secret door models.                                                           |
| [id-card-holder/](id-card-holder/README.md) | Slim single-sided portrait CR80 ID card holder with lanyard loop.             |

## Shared Assets

| Path          | Description                                                  |
| ------------- | ------------------------------------------------------------ |
| `fonts/`      | Shared Inter text fonts and Font Awesome icon fonts.         |
| `lib/qr.scad` | Shared [scadqr](https://github.com/xypwn/scadqr) QR library. |

Projects reference shared assets relative to their directory (for example, `use <../lib/qr.scad>` and `use <../fonts/Inter-Bold.ttf>`).

## Private / Local Parameter Files

Generated `.stl` files and private parameter files are ignored by git in [`.gitignore`](.gitignore):

- `personal.scad` (for example, `business-card/personal.scad` copied from `business-card/personal.example.scad`)
- `*.local.scad`, `*.private.scad`
- `*.local.svg`, `*.private.svg` (for example, a custom logo for `id-card-holder/`)

Keep real personal details in these ignored files rather than committing them.

## Licenses

This repository uses the MIT license. See [LICENSE](LICENSE). Third-party files:

- Inter: SIL Open Font License 1.1. See [fonts/Inter-LICENSE.txt](fonts/Inter-LICENSE.txt).
- Font Awesome Free: SIL Open Font License 1.1. See [fonts/FontAwesome-LICENSE.txt](fonts/FontAwesome-LICENSE.txt).
- scadqr: MIT license. See [lib/qr.scad](lib/qr.scad).

