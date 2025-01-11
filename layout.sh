#!/bin/bash

# Configuration Variables
# Name of the folder with images in input dir
input_dir_name="tsimur_blank_book_4"

# Option to choose between 2 or 4 images per photo
images_per_photo=4  # Set to 2 or 4

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
if [ "$crop_images" = true ]; then
  geometry_option="${slot_size}^"   # Crop to fill the slot
else
  geometry_option="${slot_size}"    # Scale to fit the slot
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

# Preprocess images
preprocess_images

# Process images in batches of 2 or 4, handling case-insensitive file extensions
orientation="horizontal"
if [ "$images_per_photo" -eq 4 ]; then
  orientation="vertical"
fi

for img in "$preprocessed_dir"/*.jpg; do
  # Check if the file exists to avoid processing invalid paths
  if [ -e "$img" ]; then
    processed_img=$(check_and_rotate_image "$img" "$orientation")
    images+=("$processed_img")

    counter=$((counter + 1))

    if [ $counter -eq "$images_per_photo" ]; then
      # Combine images into a tiled layout with white background and ensure each image is centered in its slot
      magick montage "${images[@]}" -tile "$tile" -geometry "$geometry_option" -background $background -gravity center -extent "$slot_size" -resize "$output_size" "$out_dir/output_batch_${batch}.jpg"

      # Clean up rotated images
      cleanup_rotated_images "${images[@]}"

      # Reset counter and images array
      counter=0
      batch=$((batch + 1))
      images=()
    fi
  fi
done

# If there are leftover images (less than the desired images per photo), process them
if [ $counter -gt 0 ]; then
  magick montage "${images[@]}" -tile "$tile" -geometry "$geometry_option" -background $background -gravity center -extent "$slot_size" -resize "$output_size" "$out_dir/output_batch_${batch}.jpg"

  # Clean up rotated images
  cleanup_rotated_images "${images[@]}"
fi
