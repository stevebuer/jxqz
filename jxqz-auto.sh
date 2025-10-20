#!/bin/bash

#
# jxqz-auto.sh - AI-generated website generation script
# Based on the original jxqz.sh by Steve Buer 2023
# Generated: October 20, 2025
#

set -euo pipefail  # Better error handling

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $0 <command> [options]

Commands:
    gen [title] [heading]    Generate HTML page with optional title and heading
    ren <name>              Rename files with sequential numbering
    rot [degrees]           Rotate images (default: 90 degrees clockwise)
    thumb [size]            Generate thumbnails (default: 175x175)
    help                    Show this help message

Examples:
    $0 gen "My Gallery" "Photo Collection"
    $0 ren vacation
    $0 rot 180
    $0 thumb 200x200

Note: Most commands read filenames from stdin (pipe or redirect input)
EOF
}

# Function to generate HTML
generate_html() {
    local title="${1:-PAGE_TITLE}"
    local heading="${2:-PAGE_HEADING}"
    
    cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${title}</title>
    <style>
        body { background-color: #ffffff; font-family: Arial, sans-serif; margin: 20px; }
        .gallery { display: flex; flex-wrap: wrap; gap: 10px; justify-content: center; }
        .gallery img { border: 1px solid #ccc; transition: transform 0.2s; }
        .gallery img:hover { transform: scale(1.05); }
        .back-link { text-align: center; margin-top: 20px; }
    </style>
</head>
<body>

<h3>${heading}</h3>

<div class="gallery">
<!-- GALLERY_CONTENT -->
EOF

    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local basename=$(basename "$file" .jpg)
            echo "    <a href=\"${file}\"><img src=\"thumbs/${basename}_t.jpg\" alt=\"${basename}\" loading=\"lazy\"></a>"
        fi
    done

    cat << EOF
</div>

<hr>
<div class="back-link">
    <a href="../index.html">← Back</a>
</div>

</body>
</html>
EOF
}

# Function to rename files
rename_files() {
    local base_name="$1"
    local counter=1
    
    if [[ -z "$base_name" ]]; then
        echo "Error: Base name required for renaming" >&2
        echo "Usage: $0 ren <name>" >&2
        exit 1
    fi
    
    echo "Renaming files with base name: $base_name"
    
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local extension="${file##*.}"
            local new_name="${base_name}${counter}.${extension}"
            echo "Renaming: $file → $new_name"
            cp "$file" "$new_name"
            ((counter++))
        else
            echo "Warning: File not found: $file" >&2
        fi
    done
}

# Function to rotate images
rotate_images() {
    local degrees="${1:-90}"
    
    # Validate degrees
    if ! [[ "$degrees" =~ ^-?[0-9]+$ ]]; then
        echo "Error: Rotation degrees must be a number" >&2
        exit 1
    fi
    
    echo "Rotating images by $degrees degrees"
    
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            echo "Rotating: $file"
            if command -v convert >/dev/null 2>&1; then
                convert "$file" -rotate "$degrees" "$file"
            elif command -v magick >/dev/null 2>&1; then
                magick "$file" -rotate "$degrees" "$file"
            else
                echo "Error: ImageMagick (convert or magick) not found" >&2
                exit 1
            fi
        else
            echo "Warning: File not found: $file" >&2
        fi
    done
}

# Function to create thumbnails
create_thumbnails() {
    local size="${1:-175x175}"
    
    # Validate size format
    if ! [[ "$size" =~ ^[0-9]+x[0-9]+$ ]]; then
        echo "Error: Size must be in format WIDTHxHEIGHT (e.g., 175x175)" >&2
        exit 1
    fi
    
    echo "Creating thumbnails with size: $size"
    mkdir -p thumbs
    
    while IFS= read -r file; do
        if [[ -f "$file" ]]; then
            local basename=$(basename "$file" .jpg)
            local thumb_file="thumbs/${basename}_t.jpg"
            echo "Creating thumbnail: $file → $thumb_file"
            
            if command -v convert >/dev/null 2>&1; then
                convert "$file" -resize "$size" "$thumb_file"
            elif command -v magick >/dev/null 2>&1; then
                magick "$file" -resize "$size" "$thumb_file"
            else
                echo "Error: ImageMagick (convert or magick) not found" >&2
                exit 1
            fi
        else
            echo "Warning: File not found: $file" >&2
        fi
    done
}

# Main script logic
case "${1:-}" in
    gen)
        shift
        generate_html "$@"
        ;;
    
    ren)
        shift
        rename_files "$@"
        ;;
    
    rot)
        shift
        rotate_images "$@"
        ;;
    
    thumb)
        shift
        create_thumbnails "$@"
        ;;
    
    help|--help|-h)
        show_usage
        ;;
    
    *)
        echo "Error: Unknown command '${1:-}'" >&2
        echo ""
        show_usage
        exit 1
        ;;
esac