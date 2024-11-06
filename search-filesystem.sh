#!/bin/bash

# Set default values for optional arguments
max_depth=2
final_step=4
patterns_file="patterns.txt"

usage_text="
# Function to display usage information
Usage: $0 base_directory [max_depth] [final_step] [patterns_file] 

Arguments:
    base_directory   The directory to start the search from (required)
    max_depth        The maximum depth to search (default: 2)
    final_step       The final \"step\" of the search (default: 4). Valid options are 1, 2, 3, or 4.
    patterns_file    The file containing patterns to search for (default: ./patterns.txt)

Options:
    -h               Show this help message and exit

Steps: (the valid options for final_step)
    1. Match filenames only
    2. Match within file contents
    3. Match file contents within .zip archives
    4. Match file contents within .gz, .tar.gz, or .7z archives

by 4wayhandshake 🤝🤝🤝🤝

"

# Function to display usage information
usage() {
    echo "$usage_text"
    if (( $# != 1 )); then
        exit 1
    else
        exit $1
    fi
}

cleanup() {
    echo -e "\n\n\033[1;34mSearch complete.\033[0m\n"
    exit 0
}

recolorize() {
    local REGEX="$1"
    # Read from stdin
    while IFS= read -r line; do
        #MATCHED_TEXT=$(echo $line | grep -i -E -o "$REGEX")
        
        # Extract text before the first colon. 
        # Note that the "inner" filepath may not actually exist, if $2 is an archive file!
        before_colon="(Inside $2) ${line%%:*}:"
        after_colon="${line#*:}"
        
        MATCHED_TEXT=$(echo $after_colon | grep -i -E -o "$REGEX")

        # Color the text before the first colon (magenta)
        colored_before="\033[35m$before_colon\033[0m"

        # Color the matching search term (red and bold)
        REDBOLD='\\033[1;31m';
        RESET='\\033[0m';
        ESCAPED_MATCHED_TEXT=$(printf '%s\n' "$MATCHED_TEXT" | sed -e 's/[\/&]/\\&/g')
        
        # Output the combined result.
        # redbold the text only if it doesnt produce errors
        if colored_after=$(echo "$after_colon" | sed -e "s/$ESCAPED_MATCHED_TEXT/${REDBOLD}&${RESET}/g" 2>/dev/null); then
            echo -e "$colored_before $colored_after"
        else
            echo -e "$colored_before $after_colon"  # Fallback if sed fails
        fi
        
    done
}

# Check for help flag or no arguments
if [ "$1" == "-h" ] || [ -z "$1" ]; then
    usage
fi

# Check if base_directory is provided
base_directory="$1"

relative_path() {
    file_path=$(realpath "$1")
    base_path=$(realpath "$2")
    rel_path=$(realpath --relative-to="$base_path" "$file_path")
    echo $rel_path
}

# Check if max_depth is provided and update it
if [ ! -z "$2" ]; then
    max_depth="$2"
fi

# Check if the max_step was provided and update it
if [ ! -z "$3" ]; then
    final_step="$3"
fi

# Check if patterns_file is provided and update it
if [ ! -z "$4" ]; then
    patterns_file=$(realpath "$4")
fi

# Check if the provided final step is valid
if [ "$final_step" -lt 1 ]; then
    echo "Error: final step '$final_step' is not valid. Please specify an integer 1 to 4"
    usage
fi

# Check if the patterns_file exists and is readable
if [ ! -r "$patterns_file" ]; then
    echo "Error: patterns_file '$patterns_file' does not exist or cannot be opened."
    usage 1
fi

# Step 1: Find files or directories matching patterns in patterns_file
echo -e "\n\033[1;34mStep 1:\033[0m Searching for files or directories whose name matches any of the patterns in '$patterns_file'...\n"
find "$base_directory" -maxdepth "$max_depth" -type f -o -type d 2>/dev/null | grep -i -E --color=always -f <(grep -v '^#' "$patterns_file")
if [ "$final_step" -lt 2 ]; then
    cleanup
fi

# Step 2: Perform a recursive grep for patterns in files
echo -e "\n\n\033[1;34mStep 2:\033[0m Performing a recursive grep for patterns in files...\n"
while IFS= read -r MATCHEDFILE; do
    RELATIVE_FILE=$(relative_path "$MATCHEDFILE" "$base_directory")
    for REGEX in $(grep -v "^#" "$patterns_file"); do
        MATCHED_OUTPUT=$(grep -i -E -a --color=always --line-number "$REGEX" "$MATCHEDFILE")
        if [ -n "$MATCHED_OUTPUT" ]; then
            printf "\n\033[35m(Inside \"%s\"):\033[0m\n" "$RELATIVE_FILE"
            echo "$MATCHED_OUTPUT"
        fi
    done
done < <(find "$base_directory" -maxdepth "$max_depth" -type f 2>/dev/null | xargs -d '\n' grep -i -E -l -f <(grep -v '^#' "$patterns_file"))

if [ "$final_step" -lt 3 ]; then
    cleanup
fi

# Step 3: Check for zipgrep and search within .zip files
echo -e "\n\n\033[1;34mStep 3:\033[0m Checking if zipgrep is available...\n"
if command -v zipgrep &> /dev/null; then
    echo -e "(\033[1;32mzipgrep is available.\033[0m Searching within .zip files...)\n"
    while IFS= read -r ZIPFILE; do 
        RELATIVE_FILE=$(relative_path "$ZIPFILE" "$base_directory")
        for REGEX in $(grep -v "^#" "$patterns_file"); do
            MATCHED_OUTPUT=$(zipgrep -i -E "$REGEX" "$ZIPFILE")
            if [ -n "$MATCHED_OUTPUT" ]; then
                echo "$MATCHED_OUTPUT" | recolorize "$REGEX" "$RELATIVE_FILE"
            fi
        done
    done < <(find "$base_directory" -maxdepth "$max_depth" -type f -name "*.zip" 2>/dev/null)
else
    echo -e "\033[1;31m...zipgrep is not available. Skipping step 3.\033[0m"
fi

if [ "$final_step" -lt 4 ]; then
    cleanup
fi

# Step 4: Check for zgrep and search within .gz, .tar.gz, and .7z files
echo -e "\n\n\033[1;34mStep 4:\033[0m Checking if tar is available...\n"
if command -v tar &> /dev/null; then
    echo -e "(\033[1;32mtar is available.\033[0m Searching within .gz, .tar.gz, and .7z files...)\n"
    while IFS= read -r GZIPFILE; do
        RELATIVE_FILE=$(relative_path "$GZIPFILE" "$base_directory")
        for REGEX in $(grep -v "^#" "$patterns_file"); do
            MATCHED_OUTPUT=$(tar xaf "$GZIPFILE" --to-command "grep -hH -i -E -a --label=\"\$TAR_FILENAME\" --color=always --with-filename --line-number '$REGEX' || true")
            if [ -n "$MATCHED_OUTPUT" ]; then
                echo "$MATCHED_OUTPUT" | recolorize "$REGEX" "$RELATIVE_FILE"
            fi
        done
    done < <(find "$base_directory" -maxdepth "$max_depth" -type f \( -name "*.gz" -o -name "*.tar.gz" -o -name "*.7z" \) 2>/dev/null)
else
    echo -e "\033[1;31m...tar is not available.\033[0m"
fi

cleanup
