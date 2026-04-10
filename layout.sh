#!/bin/bash

# Configuration Variables
# Name of the folder with images in input dir
input_dir_name="baby_boy"

# Option to choose between 2, 3, or 4 images per photo
images_per_photo=4  # Set to 2, 3, or 4

# Set this to 'true' to crop images to fit the slots, or 'false' to scale them to fit without cropping
crop_images=true

# Define background color
background="white"

# Define the directory where the images are located
input_dir="input/$input_dir_name"
out_dir="output/$input_dir_name"
preprocessed_dir="$out_dir/preprocessed"

# Define output size for 4x6 photo paper at 300 DPI (1800x1200 pixels)
output_width=1200
output_height=1800
output_size="${output_width}x${output_height}"

# Set slot layout based on images_per_photo value
if [ "$images_per_photo" -eq 2 ]; then
  tile="1x2"
  slot_width=$((output_width))
  slot_height=$((output_height / 2))
  slot_size="${slot_width}x${slot_height}"
elif [ "$images_per_photo" -eq 3 ]; then
  # 3-up: hero image on top (full width, half height), two small images on bottom
  hero_slot_width=$((output_width))
  hero_slot_height=$((output_height / 2))
  hero_slot_size="${hero_slot_width}x${hero_slot_height}"
  small_slot_width=$((output_width / 2))
  small_slot_height=$((output_height / 2))
  small_slot_size="${small_slot_width}x${small_slot_height}"
else
  tile="2x2"
  slot_width=$((output_width / 2))
  slot_height=$((output_height / 2))
  slot_size="${slot_width}x${slot_height}"
fi

# Counter for batching images
counter=0
batch=1

# Create output and preprocessing directories and clean them
mkdir -p "$out_dir"
rm -rf "$out_dir"/*
mkdir -p "$preprocessed_dir"

# Determine the geometry option based on whether to crop or scale the images
if [ "$images_per_photo" -eq 3 ]; then
  if [ "$crop_images" = true ]; then
    hero_geometry="${hero_slot_size}^"
    small_geometry="${small_slot_size}^"
  else
    hero_geometry="${hero_slot_size}"
    small_geometry="${small_slot_size}"
  fi
else
  if [ "$crop_images" = true ]; then
    geometry_option="${slot_size}^"   # Crop to fill the slot
  else
    geometry_option="${slot_size}"    # Scale to fit the slot
  fi
fi

preprocess_images() {
  for img in "$input_dir"/*.{jpg,jpeg,png,heic,JPG,JPEG,PNG,HEIC}; do
    if [ -e "$img" ]; then
      base_name=$(basename "$img")
      output_file="$preprocessed_dir/${base_name%.*}.jpg"
      # Convert to JPEG and strip orientation information
      magick "$img" -auto-orient -strip "$output_file"
    fi
  done
}

check_and_rotate_image() {
  local img="$1"
  local target_orientation="$2" # horizontal or vertical
  local rotated_img="${img%.*}_rotated.jpg"

  # Get the dimensions after auto-orienting
  local image_width=$(magick identify -format "%w" "$img")
  local image_height=$(magick identify -format "%h" "$img")

  if [ "$target_orientation" == "vertical" ] && [ "$image_width" -gt "$image_height" ]; then
    # Rotate horizontal image to vertical
    magick "$img" -rotate 90 "$rotated_img"
    echo "$rotated_img"
    return
  elif [ "$target_orientation" == "horizontal" ] && [ "$image_height" -gt "$image_width" ]; then
    # Rotate vertical image to horizontal
    magick "$img" -rotate -90 "$rotated_img"
    echo "$rotated_img"
    return
  fi

  # Return the original image if no further rotation is needed
  echo "$img"
}

cleanup_rotated_images() {
  local images=("$@")
  for img in "${images[@]}"; do
    if [[ "$img" == *_rotated.jpg ]]; then
      rm -f "$img"
    fi
  done
}

assemble_three_up() {
  local hero_img="$1"
  local small_img1="$2"
  local small_img2="$3"
  local output_file="$4"

  local tmp_hero="${out_dir}/_tmp_hero.jpg"
  local tmp_strip="${out_dir}/_tmp_strip.jpg"

  # Resize/crop the hero image to fill the top half
  magick "$hero_img" -resize "$hero_geometry" -background $background -gravity center -extent "$hero_slot_size" "$tmp_hero"

  # Montage the two small images into a bottom strip
  magick montage "$small_img1" "$small_img2" \
    -tile 2x1 -geometry "$small_geometry" \
    -background $background -gravity center -extent "$small_slot_size" \
    "$tmp_strip"

  # Stack hero on top of the bottom strip
  magick "$tmp_hero" "$tmp_strip" -append "$output_file"

  rm -f "$tmp_hero" "$tmp_strip"
}

# Preprocess images
preprocess_images

# Process images in batches, handling case-insensitive file extensions
orientation="horizontal"
if [ "$images_per_photo" -eq 4 ]; then
  orientation="vertical"
fi

for img in "$preprocessed_dir"/*.jpg; do
  if [ -e "$img" ]; then
    # For 3-up: first image is horizontal (hero), rest are vertical (small slots)
    if [ "$images_per_photo" -eq 3 ]; then
      if [ $counter -eq 0 ]; then
        img_orientation="horizontal"
      else
        img_orientation="vertical"
      fi
    else
      img_orientation="$orientation"
    fi

    processed_img=$(check_and_rotate_image "$img" "$img_orientation")
    images+=("$processed_img")

    counter=$((counter + 1))

    if [ $counter -eq "$images_per_photo" ]; then
      if [ "$images_per_photo" -eq 3 ]; then
        assemble_three_up "${images[0]}" "${images[1]}" "${images[2]}" "$out_dir/output_batch_${batch}.jpg"
      else
        magick montage "${images[@]}" -tile "$tile" -geometry "$geometry_option" -background $background -gravity center -extent "$slot_size" -resize "$output_size" "$out_dir/output_batch_${batch}.jpg"
      fi

      cleanup_rotated_images "${images[@]}"

      counter=0
      batch=$((batch + 1))
      images=()
    fi
  fi
done

# If there are leftover images (less than the desired images per photo), process them
if [ $counter -gt 0 ]; then
  if [ "$images_per_photo" -eq 3 ]; then
    if [ $counter -eq 1 ]; then
      # Single leftover: place as hero filling the full page
      magick "${images[0]}" -resize "$output_size" -gravity center -extent "$output_size" -background $background "$out_dir/output_batch_${batch}.jpg"
    else
      # Two leftovers: stack as 1x2 (each gets half the page)
      local_slot="${output_width}x$((output_height / 2))"
      if [ "$crop_images" = true ]; then
        local_geom="${local_slot}^"
      else
        local_geom="${local_slot}"
      fi
      magick montage "${images[@]}" -tile 1x2 -geometry "$local_geom" -background $background -gravity center -extent "$local_slot" -resize "$output_size" "$out_dir/output_batch_${batch}.jpg"
    fi
  else
    magick montage "${images[@]}" -tile "$tile" -geometry "$geometry_option" -background $background -gravity center -extent "$slot_size" -resize "$output_size" "$out_dir/output_batch_${batch}.jpg"
  fi

  cleanup_rotated_images "${images[@]}"
fi
