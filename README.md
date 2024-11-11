# system-automation-scripts

## Binary Image Decoder Script

## Description
This shell script decodes and displays a custom binary image format's content and validates its integrity based on specified metadata. It checks for several error types, including column count mismatches, invalid binary values, and bit-count inconsistencies.

## Prerequisites
- Ensure you have execution permissions (`chmod +x bindecode.sh`) for the script.
- Place this script in the same directory as the binary images or specify the path to the image when running.

## Usage
```sh
./bindecode.sh <imagefile>
