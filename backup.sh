#!/bin/zsh

# === Archive Variables ===
TEMP_DIR="$HOME/temp_backup"
ARCHIVE_DIR="$HOME/archives"
BACKUP_FILE="$TEMP_DIR/home_$(date +%Y%m%d_%H%M%S).zip"
COMPRESSION_LEVEL=${COMPRESSION_LEVEL:-0} # Compression level (0-9)

# === Sync Variables ===
DEFAULT_SOURCE_DIR="$HOME/Projects"
DEFAULT_DESTINATION_DIR="$HOME/Library/Mobile Documents/com~apple~CloudDocs/Projects"
RSYNC_OPTIONS="-avh --delete" # rsync options

# === Shared Variables ===
CRON_JOB="0 2 * * * $(realpath "$0")"

# Include and exclude patterns for both modes
INCLUDE_PATTERNS=(
  "*.txt"
  "*.md"
  "src/"
  "docs/"
  ".ssh"
  "Desktop"
  "Projects"
  ".aws"
  ".config"
  ".gitconfig"
  ".gnupg"
  ".kube"
  ".oh-my-zsh"
  ".profile.sh"
  ".profiles"
  ".s3.sh"
  ".viminfo"
  ".vscode"
  ".zprofile"
  ".zsh_history"
  ".zsh_sessions"
  ".zshrc"
)

EXCLUDE_PATTERNS=(
  "*.log"
  "*.tmp"
  "*.cache"
  "*.lock"
  "node_modules/"
  "dist/"
  ".git/"
  "*/.venv/*"
  "*/.next/*"
  "*/.out/*"
  "*/build/*"
  "*/dist/*"
  "*.DS_Store"
  "*/.Trash/*"
  "$TEMP_DIR/*"
  "$ARCHIVE_DIR/*"
  "$BACKUP_FILE"
  "*.pkg"
  "*/Downloads/*"
  "*/Documents/*"
  "*/Movies/*"
  "*/Pictures/*"
)

# Build include and exclude options for rsync and zip
RSYNC_INCLUDE_EXCLUDE_OPTIONS=()
ZIP_EXCLUDE_OPTIONS=()
for pattern in "${INCLUDE_PATTERNS[@]}"; do
  RSYNC_INCLUDE_EXCLUDE_OPTIONS+=(--include "$pattern")
done
for pattern in "${EXCLUDE_PATTERNS[@]}"; do
  RSYNC_INCLUDE_EXCLUDE_OPTIONS+=(--exclude "$pattern")
  ZIP_EXCLUDE_OPTIONS+=(--exclude "$pattern")
done
RSYNC_INCLUDE_EXCLUDE_OPTIONS+=(--exclude '*') # Default exclude for rsync

# === Functions ===

# Sync function
sync_directories() {
  local source_dir="${1:-$DEFAULT_SOURCE_DIR}" # Use provided or default SOURCE_DIR
  local destination_dir="${2:-$DEFAULT_DESTINATION_DIR}" # Use provided or default DESTINATION_DIR

  echo "Starting sync from $source_dir to $destination_dir"

  # Create destination directory if it doesn't exist
  mkdir -p "$destination_dir"

  # Run rsync with include and exclude patterns
  rsync $RSYNC_OPTIONS "${RSYNC_INCLUDE_EXCLUDE_OPTIONS[@]}" "$source_dir/" "$destination_dir"

  echo "Sync completed!"
}

# Archive function
archive_backup() {
  echo "Starting archive backup"

  # Create necessary directories
  mkdir -p "$TEMP_DIR" "$ARCHIVE_DIR"

  # Run zip with include and exclude options
  echo "Creating backup: $BACKUP_FILE with compression level: $COMPRESSION_LEVEL"
  zip -vr -"${COMPRESSION_LEVEL}" "$BACKUP_FILE" "${INCLUDE_PATTERNS[@]}" "${ZIP_EXCLUDE_OPTIONS[@]}"

  # Move the backup file to the archive directory
  mv "$BACKUP_FILE" "$ARCHIVE_DIR"
  FINAL_BACKUP_FILE="$ARCHIVE_DIR/$(basename "$BACKUP_FILE")"

  # Provide backup details
  echo "Backup completed: $FINAL_BACKUP_FILE"
  echo "Backup size: $(du -h "$FINAL_BACKUP_FILE" | cut -f1)"
  echo "Checksum (SHA256): $(shasum -a 256 "$FINAL_BACKUP_FILE" | awk '{print $1}')"

  # Clean up the temporary directory
  echo "Cleaning up temporary directory..."
  rm -rf "$TEMP_DIR"
}

# Function to add this script to crontab
add_to_crontab() {
  if ! crontab -l 2>/dev/null | grep -qF "$CRON_JOB"; then
    echo "Registering script in crontab..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Script registered to run daily at 2:00 AM."
  else
    echo "Script is already registered in crontab."
  fi
}

# Function to remove this script from crontab
remove_from_crontab() {
  echo "Removing script from crontab..."
  crontab -l 2>/dev/null | grep -vF "$CRON_JOB" | crontab -
  echo "Script removed from crontab."
}

# === Main Script Execution ===
case $1 in
  --sync)
    # Optional: $2 (SOURCE_DIR), $3 (DESTINATION_DIR)
    sync_directories "${2:-$DEFAULT_SOURCE_DIR}" "${3:-$DEFAULT_DESTINATION_DIR}"
    ;;
  --archive)
    archive_backup
    ;;
  --register)
    add_to_crontab
    ;;
  --unregister)
    remove_from_crontab
    ;;
  *)
    echo "Usage: $0 [--sync [SOURCE_DIR DESTINATION_DIR]|--archive|--register|--unregister]"
    ;;
esac
