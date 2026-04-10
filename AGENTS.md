# AGENTS.md — photo-collage

Guidance for AI assistants and humans working in this repository.

## What this project is

A small **bash + ImageMagick** utility that batches photos from a folder into printable **4×6 @ 300 DPI** collages (default **1200×1800** pixels). It was built for school-book style layouts: **2 images per sheet** (1×2 vertical stack), **3 images per sheet** (1 hero + 2 small), or **4 images per sheet** (2×2 grid).

There is no application server, package manager, or test suite—only `layout.sh` and documentation.

## Repository layout

| Path | Role |
|------|------|
| `layout.sh` | Main script; edit configuration at the top, then run |
| `README.md` | Origin story and the original ChatGPT prompt |
| `input/<album>/` | Put source images here (gitignored) |
| `output/<album>/` | Generated collages and `preprocessed/` JPEGs (gitignored) |
| `.gitignore` | Ignores `input/`, `output/`, `.DS_Store` |

## Prerequisites

- **Bash** (script uses bash arrays and `[[ ]]`)
- **ImageMagick 7** with the `magick` CLI on `PATH`
- **HEIC** inputs require ImageMagick built with HEIC support (or preprocess to JPEG/PNG yourself)

## How to run

1. Create `input/<album_name>/` and add `.jpg`, `.jpeg`, `.png`, or `.heic` files (case-insensitive globs are used).
2. Open `layout.sh` and set `input_dir_name` to match that folder name (default in repo: `baby_boy`).
3. Adjust `images_per_photo` (`2`, `3`, or `4`), `crop_images` (`true` / `false`), and `background` if needed.
4. From the repo root:

   ```bash
   bash layout.sh
   ```

   Or: `chmod +x layout.sh` once, then `./layout.sh`.

## Configuration (top of `layout.sh`)

- **`input_dir_name`** — subfolder under `input/` to read from.
- **`images_per_photo`** — `2` (1×2) or `4` (2×2).
- **`crop_images`** — `true`: fill each slot and crop (`geometry` ends with `^`). `false`: scale to fit without cropping.
- **`background`** — montage background color (e.g. `white`).
- **`output_width` / `output_height`** — canvas size in pixels (documented in script as 4×6 @ 300 DPI).

## Processing behavior (for maintainers)

1. **Preprocess**: All matching inputs are converted with `magick … -auto-orient -strip` into `output/<album>/preprocessed/*.jpg`.
2. **Orientation**: For 4-up layouts, images are nudged toward **vertical** slots; for 2-up, toward **horizontal** slots (`check_and_rotate_image`). Temporary `*_rotated.jpg` files are removed after each batch.
3. **Batching**: Preprocessed JPEGs are walked in glob order; every 2 or 4 images become `output_batch_<n>.jpg`. A final short batch is still montaged if the count is not a multiple of `images_per_photo`.

Montage uses `magick montage` with `-tile`, `-geometry`, `-gravity center`, `-extent` per slot, and a final `-resize` to the full output dimensions.

## Conventions for edits

- Keep changes **focused** on `layout.sh` unless the user asks for docs or repo wiring.
- Prefer **clear variable names** and short comments consistent with the existing style.
- Do not commit **`input/`** or **`output/`**; they are intentionally ignored.
- If adding formats or options, preserve **case-insensitive** behavior where the script already uses multiple globs.

## Known quirks to respect

- Output dimensions in comments vs. README: both target **1200×1800** for portrait 4×6; the script’s `output_width`/`output_height` are the source of truth.
- Glob iteration order is **filesystem-dependent**; deterministic ordering is not implemented—mention this if users need a specific sequence.

## Suggested verification after changes

Run the script against a small fixture folder under `input/` and confirm:

- Expected number of `output_batch_*.jpg` files
- Slot filling/cropping vs. letterboxing matches `crop_images`
- No leftover `*_rotated.jpg` in `preprocessed/` after a successful run
