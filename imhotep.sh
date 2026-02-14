#!/bin/bash

# Exit early on any error
set -euo pipefail

# Function to print usage
usage() {
    cat <<EOF
Usage:
  imhotep init --dir <value> --view <value>
  imhotep mount  --dir <value> --view <value>
  imhotep unmount --view <value>

Commands:
  init                  Initialize encrypted directory
  mount                 Mount encrypted directory
  unmount               Unmount decrypted view

Options:
  --dir <value>         Cipher directory
  --view <value>        Plain text mount directory
EOF
    exit 1
}

# Check we have at least one argument (command)
if [[ $# -lt 1 ]]; then
    usage
fi

# First argument is the command
COMMAND="$1"
shift

# Initialize option values
dir=""
view=""

# Parse arguments
PARSED=$(getopt --options="" \
                --longoptions="dir:,view:" \
                --name "$0" -- "$@") || usage

# If getopt fails, exit
if [[ $? -ne 0 ]]; then
    exit 1
fi

# Reorder arguments
eval set -- "$PARSED"

# Extract options
while true; do
    case "$1" in
        --dir)
            dir="$2"
            shift 2
            ;;
        --view)
            view="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Unexpected option: $1"
            exit 1
            ;;
    esac
done

# Validate arguments based on command
case "$COMMAND" in
    init|mount)
        [[ -z "$dir" ]] && { echo -e "--dir is required for $COMMAND\n"; usage; }
        [[ -z "$view" ]] && { echo -e "--view is required for $COMMAND\n"; usage; }
        ;;
    unmount)
        [[ -n "$dir" ]] && { echo -e "--dir is not used for unmount\n"; usage; }
        [[ -z "$view" ]] && { echo -e "--view is required for unmount\n"; usage; }
        ;;
    *)
        echo "Unknown command: $COMMAND"
        usage
        ;;
esac

# Create and mount encrypted directory with a decrypted view
init() {
    mkdir $dir $view
    gocryptfs -init $dir
    echo "Initialised $dir"
    mount
}

# Mount encrypted directory with a decrypted view
mount() {
    # Remake view incase in the case of unmount ran first
    if [[ ! -d "$view" ]]; then
        mkdir -p "$view"
    fi
    gocryptfs $dir $view
    echo "Mounted $dir with $view view"
}

# Unmount decrypted view
unmount() {
    fusermount -u $view
    rm -rf $view
    echo "Unmounted $view"
}

# Execute command
case "$COMMAND" in
    init)
        init
        ;;
    mount)
        mount
        ;;
    unmount)
        unmount
        ;;
esac