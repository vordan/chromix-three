#!/bin/bash

# SVG to PNG Icon Generator
# Usage: ./svg2icons.sh [options] <svg_file>

set -e  # Exit on error

# Default values
PREFIX="icon-"
SIZES="16,32,48"
SVG_FILE=""
INPUT_DIR="."
OUTPUT_DIR="."
VERBOSE=true
QUIET=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display usage
usage() {
    echo -e "${BLUE}SVG to PNG Icon Generator${NC}"
    echo ""
    echo "Usage: $0 [options] <svg_file>"
    echo ""
    echo "Options:"
    echo "  -p, --prefix STRING    Output file prefix (default: 'icon-')"
    echo "  -s, --sizes LIST       Comma-separated list of sizes (default: '16,32,48')"
    echo "  -i, --input DIR        Input directory (default: current directory)"
    echo "  -o, --output DIR       Output directory (default: same as input)"
    echo "  -q, --quiet            Suppress verbose output"
    echo "  -h, --help             Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 master.svg"
    echo "  $0 -i ./svg -o ./png master.svg"
    echo "  $0 -p app- -s 32,64,128,256 master.svg"
    echo "  $0 --prefix myicon- --sizes 16,24,32,48,64,128 --output ./icons/ master.svg"
    exit 1
}

# Function to print colored messages
print_info() {
    if [ "$VERBOSE" = true ] && [ "$QUIET" = false ]; then
        echo -e "${GREEN}[INFO]${NC} $1"
    fi
}

print_step() {
    if [ "$VERBOSE" = true ] && [ "$QUIET" = false ]; then
        echo -e "${BLUE}[STEP]${NC} $1"
    fi
}

print_success() {
    if [ "$QUIET" = false ]; then
        echo -e "${GREEN}✓${NC} $1"
    fi
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        -s|--sizes)
            SIZES="$2"
            shift 2
            ;;
        -i|--input)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -q|--quiet)
            VERBOSE=false
            QUIET=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            print_error "Unknown option: $1"
            usage
            ;;
        *)
            SVG_FILE="$1"
            shift
            ;;
    esac
done

# Set output directory to input directory if not explicitly set
if [ "$OUTPUT_DIR" = "." ] && [ "$INPUT_DIR" != "." ]; then
    OUTPUT_DIR="$INPUT_DIR"
fi

# Ensure input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    print_error "Input directory not found: $INPUT_DIR"
    exit 1
fi

# Construct full SVG file path
if [[ "$SVG_FILE" != /* ]] && [[ "$SVG_FILE" != .* ]]; then
    SVG_PATH="$INPUT_DIR/$SVG_FILE"
else
    SVG_PATH="$SVG_FILE"
fi

# Check if SVG file is provided
if [ -z "$SVG_FILE" ]; then
    print_error "No SVG file specified."
    usage
fi

# Check if SVG file exists
if [ ! -f "$SVG_PATH" ]; then
    print_error "SVG file not found: $SVG_PATH"
    echo "Looking in directory: $INPUT_DIR"
    exit 1
fi

# Check if Inkscape is installed
if ! command -v inkscape &> /dev/null; then
    print_error "Inkscape is not installed or not in PATH."
    echo "Please install Inkscape first:"
    echo "  Ubuntu/Debian: sudo apt-get install inkscape"
    echo "  Fedora: sudo dnf install inkscape"
    echo "  macOS: brew install inkscape"
    echo "  Windows: Download from https://inkscape.org"
    exit 1
fi

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Convert comma-separated sizes to array
IFS=',' read -ra SIZE_ARRAY <<< "$SIZES"

print_step "Starting SVG to PNG conversion"
print_info "Input file:    $SVG_PATH"
print_info "Input dir:     $INPUT_DIR"
print_info "Output dir:    $OUTPUT_DIR"
print_info "Output prefix: $PREFIX"
print_info "Sizes:         ${SIZE_ARRAY[*]}"
echo ""

# Process each size
success_count=0
for size in "${SIZE_ARRAY[@]}"; do
    # Remove any whitespace from size
    size=$(echo "$size" | tr -d '[:space:]')

    # Validate size is a number
    if ! [[ "$size" =~ ^[0-9]+$ ]]; then
        print_error "Invalid size: '$size'. Skipping..."
        continue
    fi

    # Construct output filename
    output_file="${OUTPUT_DIR}/${PREFIX}${size}.png"

    print_info "Converting to ${size}x${size}..."
    print_info "  Output: $output_file"

    # Run inkscape command WITHOUT suppressing errors
    print_info "  Executing: inkscape -w $size -h $size -o \"$output_file\" \"$SVG_PATH\""

    if inkscape -w "$size" -h "$size" -o "$output_file" "$SVG_PATH"; then
        print_success "Created: $(basename "$output_file")"
        # Now this should work safely:
        ((success_count++)) || true  # The "|| true" prevents exit on error
    else
        print_error "Failed to create: $output_file (Exit code: $?)"
    fi

    # Add a small delay between conversions (optional, but can help)
    sleep 0.1
done

# Summary
echo ""
echo "========================================"
echo "Conversion complete!"
echo "========================================"
echo "Successfully created: $success_count out of ${#SIZE_ARRAY[@]} icons"
echo "Output directory: $OUTPUT_DIR"

if [ $success_count -eq ${#SIZE_ARRAY[@]} ]; then
    echo -e "${GREEN}✓ All icons created successfully!${NC}"
elif [ $success_count -gt 0 ]; then
    echo -e "${YELLOW}⚠ Some icons were created ($success_count/${#SIZE_ARRAY[@]})${NC}"
else
    echo -e "${RED}✗ No icons were created${NC}"
fi
