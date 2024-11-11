#!/bin/sh
#################################
# SCRIPT INFORMATION
#################################
# Author: Laura
# Date: Oct 9, 2024
# Purpose: Decodes and validates a custom binary image format
#          and displays content with error-checking
#################################

#################################
#################################
   IMGVAL='$@B%8&WM#*oahkbdpqwmZO0QLCJUYXzcvunxrjft//|()1{}[]?-_+~<>i!lI;:,"^``.'
   NL=$'\n'
   FONTRED='\033[1;31m'
   FONTBLACK='\033[0m'
   FONTREVERSE='\033[7m'
   FONTBLINK='\033[5m'
   ERRORVAL="${FONTRED}${FONTREVERSE}${FONTBLINK}X${FONTBLACK}"
#################################

# Check if an image file name is provided
if [ $# -eq 0 ]; then
  echo "Usage: ./bindecode.sh <imagefile>"
  echo "<imagefile> should be in the kit501 binary image format."
  exit 1
fi

# Assign file name from argument and check if it exists and is readable
imagefile=$1
if [ ! -f "$imagefile" ]; then
  echo "Error: The image file '$imagefile' does not exist."
  exit 1
fi
if [ ! -r "$imagefile" ]; then
  echo "Error: The image file '$imagefile' is not readable."
  exit 1
fi

# Parse meta information
IFS=":" read -r num_chars img_width img_height img_title < "$imagefile"
width=$(echo "$img_width" | cut -d'W' -f1)
height=$(echo "$img_height" | cut -d'H' -f1)
chars=$(echo "$num_chars" | cut -d'C' -f1)

# Display meta information
echo "-------------------------------------------"
echo "File Information:"
echo "-------------------------------------------"
echo "Reported number of characters:  $chars"
echo "Reported number of columns:     $width"
echo "Reported number of rows:        $height"
echo "Image title:                    $img_title"
echo "-------------------------------------------"

# Validate reported values
if ! echo "$chars $width $height" | grep -qE '^[0-9]+ [0-9]+ [0-9]+$'; then
  echo "Error: Invalid meta information with non-numeric values."
  exit 1
fi
expected_chars=$((width * height))
if [ "$chars" -ne "$expected_chars" ]; then
   echo "Error: Mismatch between reported character count ($chars) and calculated ($expected_chars)."
   exit 1
fi

# Initialize counters and validation flags
row_num=-1
valid_image=true
error_summary=""
actual_row_count=0
actual_char_count=0

# Read image data
while read -r line; do
 if [ $row_num -eq -1 ]; then row_num=$((row_num + 1)); continue; fi
 actual_row_count=$((actual_row_count + 1))  
 col_num=0
 row_output=""
 num_value=$(echo "$line" | wc -w)
 if [ "$num_value" -ne "$width" ]; then
    row_output="$row_output$ERRORVAL"
    error_summary+="[Row:$row_num]: COLUMN COUNT ERROR - Expected $width but found $num_value\n"
    valid_image=false
 fi
 for binary_value in $line; do
    actual_char_count=$((actual_char_count + 1))
    binary_length=${#binary_value}
    if [[ "$binary_length" -ne 24 ]]; then
	  row_output="$row_output$ERRORVAL"
	  error_summary+="[$row_num,$col_num] Binary bit count error in value: $binary_value\n"
	  valid_image=false
      col_num=$((col_num + 1)); continue
     fi
   if ! echo "$binary_value" | grep -qE '^[01]+$'; then
      if echo "$binary_value" | grep -q '[2-9]'; then
            row_output="$row_output$ERRORVAL"
            error_summary+="[$row_num,$col_num] Non-binary digit in value: $binary_value\n"
            valid_image=false
            col_num=$((col_num + 1)); continue
       fi
       if echo "$binary_value" | grep -q '[^a-zA-Z0-9]'; then
            row_output="$row_output$ERRORVAL"
            error_summary+="[$row_num,$col_num] Invalid character in value: $binary_value\n"
            valid_image=false
            col_num=$((col_num + 1)); continue
       fi
       if echo "$binary_value" | grep -q '[a-zA-Z]'; then
            row_output="$row_output$ERRORVAL"
	    error_summary+="[$row_num,$col_num] Alphabetic character in value: $binary_value\n"
	    valid_image=false
            col_num=$((col_num + 1)); continue
      fi
   fi
   row_bin=$(echo "$binary_value" | cut -c1-8)
   col_bin=$(echo "$binary_value" | cut -c9-16)
   char_bin=$(echo "$binary_value" | cut -c17-24)
   row_idx=$((2#$row_bin))
   col_idx=$((2#$col_bin))
   char_idx=$((2#$char_bin))
   if [ "$row_idx" -ne "$row_num" ]; then
     row_output="$row_output$ERRORVAL"
     error_summary+="[$row_num,$col_num] Row mismatch: $row_idx != $row_num\n"
     valid_image=false
   fi
   if [ "$col_idx" -ne "$col_num" ]; then
     row_output="$row_output$ERRORVAL"
     error_summary+="[$row_num,$col_num] Column mismatch: $col_idx != $col_num\n"
     valid_image=false
   fi
   char=$(echo "$IMGVAL" | cut -c$(($char_idx + 1)))
   row_output="$row_output$char"
   col_num=$((col_num + 1))
  done
  echo -e "$row_output"
  row_num=$((row_num + 1))
done < "$imagefile"
if [ "$actual_row_count" -ne "$height" ]; then
  error_summary+="[Global] Invalid row count: $actual_row_count != $height\n"
  valid_image=false
fi
if [ "$actual_char_count" -ne "$chars" ]; then
  error_summary+="[Global] Invalid character count: $actual_char_count != $chars\n"
  valid_image=false
fi
if [ "$valid_image" = false ]; then
   echo "******************************"
   echo -e "${FONTRED}${FONTBLINK}Errors found:${FONTBLACK}"
   echo -e "$error_summary"
   echo "******************************"
else
   echo "******************************"
   echo "Valid image!"
   echo "******************************"
fi
