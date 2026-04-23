#!/bin/bash

# Define directories
CURRENT_DIR="$(pwd)"
CUSTOM_FORMATS_DIR="${CURRENT_DIR}/custom_formats"
REGEX_PATTERNS_DIR="${CURRENT_DIR}/regex_patterns"
SOURCE_REGEX_DIR="../profilarr-trash-guides/regex_patterns"

# Check if directories exist
if [[ ! -d "$CUSTOM_FORMATS_DIR" ]]; then
    echo "Error: custom_formats directory not found at $CUSTOM_FORMATS_DIR"
    exit 1
fi

if [[ ! -d "$SOURCE_REGEX_DIR" ]]; then
    echo "Error: Source regex_patterns directory not found at $SOURCE_REGEX_DIR"
    exit 1
fi

# Create regex_patterns directory if it doesn't exist
mkdir -p "$REGEX_PATTERNS_DIR"

# Initialize counters
copied=0
not_found=0
skipped_duplicates=0
skipped_existing=0

# Array to store unique patterns
declare -A seen_patterns

echo "Scanning German* files in custom_formats..."
echo "============================================"

# Find all German* files
for file in "${CUSTOM_FORMATS_DIR}"/German*; do
    if [[ -f "$file" ]]; then
        echo ""
        echo "Processing: $(basename "$file")"
        
        # Extract all pattern values from the file
        patterns=$(grep -oP '^\s*pattern:\s*\K.*$' "$file")
        
        if [[ -z "$patterns" ]]; then
            echo "  No patterns found in this file"
            continue
        fi
        
        # Process each pattern
        while IFS= read -r pattern; do
            # Remove leading/trailing whitespace only
            pattern=$(echo "$pattern" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
            
            if [[ -z "$pattern" ]]; then
                continue
            fi
            
            # Use the pattern as-is with .yml extension
            pattern_file="${pattern}.yml"
            
            # Check if we've already processed this pattern
            if [[ -n "${seen_patterns[$pattern_file]}" ]]; then
                echo "  ⊘ Skipped (duplicate): $pattern_file"
                ((skipped_duplicates++))
                continue
            fi
            
            # Mark this pattern as seen
            seen_patterns[$pattern_file]=1
            
            source_file="${SOURCE_REGEX_DIR}/${pattern_file}"
            dest_file="${REGEX_PATTERNS_DIR}/${pattern_file}"
            
            # Check if file already exists in destination
            if [[ -f "$dest_file" ]]; then
                echo "  ⊘ Skipped (already exists): $pattern_file"
                ((skipped_existing++))
                continue
            fi
            
            if [[ -f "$source_file" ]]; then
                cp "$source_file" "$dest_file"
                echo "  ✓ Copied: $pattern_file"
                ((copied++))
            else
                echo "  ✗ Not found: $pattern_file (looked for: $source_file)"
                ((not_found++))
            fi
        done <<< "$patterns"
    fi
done

echo ""
echo "============================================"
echo "Summary:"
echo "  Files copied: $copied"
echo "  Duplicates skipped: $skipped_duplicates"
echo "  Already existing (skipped): $skipped_existing"
echo "  Files not found: $not_found"
