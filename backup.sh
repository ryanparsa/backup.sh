#!/bin/zsh

# Define directories
TEMP_DIR="$HOME/temp_backup"
ARCHIVE_DIR="$HOME/archives"
BACKUP_FILE="$TEMP_DIR/home_$(date +%Y%m%d_%H%M%S).zip"

# Define the cron job line
CRON_JOB="0 2 * * * $(realpath "$0")"

# Default compression level (0-9, 0 is no compression, 9 is maximum compression)
COMPRESSION_LEVEL=${COMPRESSION_LEVEL:-0}

# Define the directories to include in the backup
INCLUDE_DIRS=(
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
  ".ssh"
  ".venv.sh"
  ".viminfo"
  ".vscode"
  ".zprofile"
  ".zsh_history"
  ".zsh_sessions"
  ".zshrc"
)

# Define the patterns to exclude
EXCLUDE_PATTERNS=(
  # Temporary files
  "*.tmp"
  "*.log"
  "*.swp"

  # Development environment files
  "*/.venv/*"
  "*.cache"
  "*.lock"

  # Build directories
  "*/.next/*"
  "*/.out/*"
  "*/build/*"
  "*/dist/*"

  # Version control and metadata
  "*/.git/*"
  "*/.svn/*"
  "*/.hg/*"

  # Package manager files
  "*/node_modules/*"
  "*/.venv/*"
  "*/venv/*"
  "*/.mypy_cache/*"
  "*/.pytest_cache/*"

  # macOS-specific files
  "*.DS_Store"
  "*/.Trash/*"
  "*/.Spotlight-V100/*"
  "*/.TemporaryItems/*"

  # Virtual machines and heavy files
  "*/Virtual Machines.localized/*"
  "*.iso"

  # Terraform-specific files
  "*/.terraform/*"

  # Go-specific files
  "*/go/pkg/*"
  "*/go/bin/*"
  "*/go/src/*"

  # Rust-specific files
  "*/target/*"

  # Exclude backup-related directories and files
  "$TEMP_DIR/*"
  "$ARCHIVE_DIR/*"
  "$BACKUP_FILE"

  # VSCode and non-critical directories
  "~/.vscode/"
  "*/Downloads/*"
  "*.pkg"
  "*/Documents/*"
  "*/Movies/*"
  "*/Pictures/*"
)

# Function to add this script to crontab
add_to_crontab() {
  # Check if the cron job is already registered
  if ! crontab -l 2>/dev/null | grep -qF "$CRON_JOB"; then
    echo "Registering script in crontab..."
    (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
    echo "Script registered to run daily at 2:00 AM."
  else
    echo "Script is already registered in crontab."
  fi
}

# Function to clean up the temporary directory
cleanup_temp_dir() {
  if [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
  fi
}

# Function to perform the backup
perform_backup() {
  # Create necessary directories
  mkdir -p "$TEMP_DIR" "$ARCHIVE_DIR"

  # Build the exclude options for the zip command
  EXCLUDE_OPTIONS=()
  for pattern in "${EXCLUDE_PATTERNS[@]}"; do
    EXCLUDE_OPTIONS+=(--exclude "$pattern")
  done

  # Run the zip command with the specified include and exclude options and compression level
  echo "Creating backup: $BACKUP_FILE with compression level: $COMPRESSION_LEVEL"
  zip -vr -"${COMPRESSION_LEVEL}" "$BACKUP_FILE" "${INCLUDE_DIRS[@]}" "${EXCLUDE_OPTIONS[@]}"

  # Move the backup file to the archive directory
  mv "$BACKUP_FILE" "$ARCHIVE_DIR"
  FINAL_BACKUP_FILE="$ARCHIVE_DIR/$(basename "$BACKUP_FILE")"

  # Provide backup details
  echo "Backup completed: $FINAL_BACKUP_FILE"
  echo "Backup size: $(du -h "$FINAL_BACKUP_FILE" | cut -f1)"
  echo "Checksum (SHA256): $(shasum -a 256 "$FINAL_BACKUP_FILE" | awk '{print $1}')"

  # Clean up the temporary directory
  cleanup_temp_dir
}

# Main script execution
case $1 in
  --register)
    add_to_crontab
    ;;
  *)
    perform_backup
    ;;
esac
