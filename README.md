# Photo collage

Turn a folder of photos into print-ready **4×6 inch** collages at **300 DPI** (1200×1800 pixels). Handy for school books, photo labs, or any workflow where you want **two photos stacked** or **four photos in a grid** on one sheet—without fighting flaky web tools.

## What you need

- **macOS, Linux, or similar** with Bash
- **ImageMagick 7** installed and available as `magick` on your PATH  
  (HEIC files need ImageMagick built with HEIC support, or convert them to JPEG/PNG first)

## Quick start

1. **Clone or download** this repo.

2. **Put your photos** in a folder under `input/`, for example:

   ```text
   input/my_album/photo1.jpg
   input/my_album/photo2.heic
   ```

3. **Edit the settings** at the top of `layout.sh`:
   - `input_dir_name` — must match your folder name (e.g. `my_album`)
   - `images_per_photo` — `2` (one column, two rows) or `4` (2×2 grid)
   - `crop_images` — `true` to fill each cell and crop, `false` to fit without cropping (may show more background)

4. **Run the script** from the project root:

   ```bash
   bash layout.sh
   ```

5. **Find the results** under `output/<your_folder_name>/`:
   - `output_batch_1.jpg`, `output_batch_2.jpg`, … — the collages
   - `preprocessed/` — normalized JPEGs the script builds from your originals (auto-orient, metadata stripped)

The `input/` and `output/` folders are gitignored so your photos stay local.

## Layout summary

| `images_per_photo` | Layout | Good for |
|--------------------|--------|----------|
| `2` | 1×2 (stacked) | Tall portraits side-by-side on the sheet |
| `4` | 2×2 | Classic contact-sheet style |

Images are centered in each cell. The script can rotate shots so they better match the slot shape (e.g. vertical slots for the 4-up layout).

## More detail

For behavior notes, edge cases, and conventions when changing the script, see **[AGENTS.md](./AGENTS.md)**.

---

## How this project started

I needed **2-up and 4-up** collages for my kids’ school books. Online tools were awkward, so I iterated with ChatGPT until the script did what I wanted. The core idea came from this prompt (paths and variable names in the prompt differ slightly from today’s `layout.sh`, but the behavior matches):

<details>
<summary>Original ChatGPT prompt</summary>

```
Hi, I need an ImageMagick CLI script for combining images located in a folder. Here are my requirements:

Images should be in the pics directory, and output should go to a directory specified by an out_dir variable.
The output image should be sized for 4x6 photo paper at 300 DPI (1200x1800 pixels).
I want to be able to choose whether to include either 2 or 4 images per output photo with a variable images_per_photo.
For 2 images per photo, images should be tiled vertically in a 1x2 layout.
For 4 images per photo, images should be in a 2x2 layout.
The images in each "slot" should be centered, with the option to either crop or scale them to fit the slot:
Set a crop_images variable to true if I want cropping, or false to scale without cropping.
It should also support case-insensitive file extensions and include .jpg, .jpeg, .png, and .heic images.
Make sure there are no shifts to the left or right in the slots, regardless of input image size.
Please generate this script for me. Thanks!
```

</details>
