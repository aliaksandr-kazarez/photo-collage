#!/bin/bash

# Configuration Variables
# Name of the folder with images in input dir
input_dir_name="pics_2"

# Option to choose between 2 or 4 images per photo
images_per_photo=2  # Set to 2 or 4

# Set this to 'true' to crop images to fit the slots, or 'false' to scale them to fit without cropping
crop_images=true

# Define background color
background="white"

# Define the directory where the images are located
input_dir="input/$input_dir_name"
out_dir="output/$input_dir_name"

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

# Create output directory and clean it
mkdir -p "$out_dir"
rm -f "$out_dir"/*

# Determine the geometry option based on whether to crop or scale the images
if [ "$crop_images" = true ]; then
  geometry_option="${slot_size}^"   # Crop to fill the slot
else
  geometry_option="${slot_size}"    # Scale to fit the slot
fi

# Process images in batches of 2 or 4, handling case-insensitive file extensions
for img in "$input_dir"/*.{jpg,jpeg,png,heic,JPG,JPEG,PNG,HEIC}; do
  # Check if the file exists to avoid processing invalid paths
  if [ -e "$img" ]; then
    # Rotate image if images_per_photo is set to 2
    if [ "$images_per_photo" -eq 2 ]; then
      rotated_img="${img%.*}_rotated.jpg"
      magick "$img" -rotate 90 "$rotated_img"
      images+=("$rotated_img")
    else
      images+=("$img")
    fi

    counter=$((counter + 1))

    if [ $counter -eq "$images_per_photo" ]; then
      # Combine images into a tiled layout with white background and ensure each image is centered in its slot
      magick montage "${images[@]}" -tile "$tile" -geometry "${geometry_option}" -background $background -gravity center -extent "${slot_size}" -resize "${output_size}" "$out_dir/output_batch_${batch}.jpg"
      
      # Clean up rotated images if created
      if [ "$images_per_photo" -eq 2 ]; then
        rm -f "${images[@]}"
      fi

      # Reset counter and images array
      counter=0
      batch=$((batch + 1))
      images=()
    fi
  fi
done

# If there are leftover images (less than the desired images per photo), process them
if [ $counter -gt 0 ]; then
  magick montage "${images[@]}" -tile "$tile" -geometry "${geometry_option}" -background $background -gravity center -extent "${slot_size}" -resize "${output_size}" "$out_dir/output_batch_${batch}.jpg"
  
  # Clean up rotated images if created
  if [ "$images_per_photo" -eq 2 ]; then
    rm -f "${images[@]}"
  fi
fi
