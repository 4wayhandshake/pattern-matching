#!/bin/bash

# Set default values for optional arguments
max_depth=2
patterns_file="patterns.txt"
final_step=4

# Function to display usage information
usage() {
    echo -e "Usage: $0 base_directory [max_depth] [patterns_file]"
    echo
    echo "Arguments:"
    echo "  base_directory   The directory to start the search from (required)"
    echo "  max_depth        The maximum depth to search (default: 2)"
    echo "  patterns_file    The file containing patterns to search for (default: ./patterns.txt)"
    echo "  final_step       The final \"step\" of the search (default: 4). Valid options are 1, 2, 3, or 4."
    echo
    echo "Options:"
    echo "  -h               Show this help message and exit"
    echo 
    echo "Steps:"
    echo "  1. Matching filenames"
    echo "  2. Matching file contents"
    echo "  3. Matching file contents within .zip archives"
    echo "  4. Matching file contents within .gz, .tar.gz, or .7z archives"
    echo
    exit 1
}

# Check for help flag or no arguments
if [ "$1" == "-h" ] || [ -z "$1" ]; then
    usage
fi

# Check if base_directory is provided
base_directory="$1"

# Check if max_depth is provided and update it
if [ ! -z "$2" ]; then
    max_depth="$2"
fi

# Check if patterns_file is provided and update it
if [ ! -z "$3" ]; then
    patterns_file="$3"
fi

# Check if the max_step was provided and update it
if [ ! -z "$4" ]; then
    final_step="$4"
fi

# Check if the patterns_file exists and is readable
if [ ! -r "$patterns_file" ]; then
    echo "Error: patterns_file '$patterns_file' does not exist or cannot be opened."
    usage
    exit 1
fi

# Check if the provided final step is valid
if [ "$final_step" -lt 1 ]; then
    echo "Error: final step '$final_step' is not valid. Please specify an integer 1 to 4"
    usage
    exit 1
fi

# Step 1: Find files or directories matching patterns in patterns_file
echo -e "\n\033[1;34mStep 1:\033[0m Searching for files or directories whose name matches any of the patterns in '$patterns_file'...\n"
find "$base_directory" -maxdepth "$max_depth" -type f -o -type d 2>/dev/null | grep -i -E --color=always -f "$patterns_file"
echo -e "\n\033[1;34mStep 1 completed.\033[0m"

if [ "$final_step" -lt 2 ]; then
    echo -e "\n\033[1;34mScript complete.\033[0m"
    exit 0
fi

# Step 2: Perform a recursive grep for patterns in files
echo -e "\n\n\033[1;34mStep 2:\033[0m Performing a recursive grep for patterns in files...\n"
find "$base_directory" -maxdepth "$max_depth" -type f 2>/dev/null | xargs grep -i -E --color=always -f "$patterns_file" --with-filename --line-number
echo -e "\n\033[1;34mStep 2 completed.\033[0m"

if [ "$final_step" -lt 3 ]; then
    echo -e "\n\033[1;34mScript complete.\033[0m"
    exit 0
fi

# Step 3: Check for zipgrep and search within .zip files
echo -e "\n\n\033[1;34mStep 3:\033[0m Checking if zipgrep is available...\n"
if command -v zipgrep &> /dev/null; then
    echo -e "(\033[1;32mzipgrep is available.\033[0m Searching within .zip files...)\n"
    find "$base_directory" -maxdepth "$max_depth" -type f -name "*.zip" 2>/dev/null | xargs zipgrep -i -E --color=always -f "$patterns_file" --with-filename --line-number
else
    echo -e "\033[1;31mzipgrep is not available.\033[0m"
fi
echo -e "\n\033[1;34mStep 3 completed.\033[0m"

if [ "$final_step" -lt 4 ]; then
    echo -e "\n\033[1;34mScript complete.\033[0m"
    exit 0
fi

# Step 4: Check for zgrep and search within .gz, .tar.gz, and .7z files
echo -e "\n\n\033[1;34mStep 4:\033[0m Checking if zgrep is available...\n"
if command -v zgrep &> /dev/null; then
    echo -e "(\033[1;32mzgrep is available.\033[0m Searching within .gz, .tar.gz, and .7z files...)\n"
    find "$base_directory" -maxdepth "$max_depth" -type f \( -name "*.gz" -o -name "*.tar.gz" -o -name "*.7z" \) 2>/dev/null | xargs zgrep -i -E --color=always -f "$patterns_file" --with-filename --line-number
else
    echo -e "\033[1;31mzgrep is not available.\033[0m"
fi
echo -e "\n\033[1;34mStep 4 completed.\033[0m"
