#!/bin/bash

# Define the directory where the images are located
input_dir="pics_2"
output_dir="${input_dir}/out"

# Define output size for 4x6 photo paper at 300 DPI (1800x1200 pixels)
output_width=1200
output_height=1800
output_size="${output_width}x${output_height}"

# Each slot size (half of the output image size)
slot_width=$((output_width / 2))    # 600 pixels
slot_height=$((output_height / 2))  # 900 pixels
slot_size="${slot_width}x${slot_height}"

# Define background color
background="white"

# Set this to 'true' to crop images to fit the slots, or 'false' to scale them to fit without cropping
crop_images=false

# Counter for batching images
counter=0
batch=1

# Create output directory
mkdir -p $output_dir

# Determine the geometry option based on whether to crop or scale the images
if [ "$crop_images" = true ]; then
  geometry_option="${slot_size}^"   # Crop to fill the slot
else
  geometry_option="${slot_size}"    # Scale to fit the slot
fi

# Process images in batches of 4 from the pics directory (handling jpg, jpeg, and png formats)
for img in "$input_dir"/*.{jpg,jpeg,png,HEIC}; do
  # Check if the file exists to avoid processing invalid paths
  if [ -e "$img" ]; then
    images+=("$img")
    counter=$((counter + 1))

    if [ $counter -eq 4 ]; then
      # Combine 4 images into a tiled layout with white background and ensure each image is centered in its slot
      montage "${images[@]}" -tile 2x2 -geometry "${geometry_option}" -background $background -gravity center -extent "${slot_size}" -resize "${output_size}" "${output_dir}/output_batch_${batch}.jpg"
      
      # Reset counter and images array
      counter=0
      batch=$((batch + 1))
      images=()
    fi
  fi
done

# If there are leftover images (less than 4), process them
if [ $counter -gt 0 ]; then
  montage "${images[@]}" -tile 2x2 -geometry "${geometry_option}" -background $background -gravity center -extent "${slot_size}" -resize "${output_size}" "${output_dir}/output_batch_${batch}.jpg"
fi
