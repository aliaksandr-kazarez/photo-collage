I needed a 4x4 collages for my kids school books, but online tools were super bad...
I did couple of rounds on ChatGPT conversations to generate this sctipt wihch uses ImageMagicCLI scripts to 
generate images i neede, and it worked out perfect

Prompt:

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