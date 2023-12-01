#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
GREY='\033[0;37m'
NC='\033[0m' # No Color

backup_folder="/data/k8s/backup"
daily_backup_days=7
weekly_backup_weeks=5
monthly_backup_months=12

if [ ! -d "$backup_folder" ]; then
    echo -e "${RED}Backup folder not found: ${YELLOW}${backup_folder}${NC}"
    exit 1
fi

current_date=$(date +%s)

# Associative arrays for keeping track of directories
declare -A keep_dirs  # Tracks directories to be kept
declare -A week_dirs  # Tracks most recent directory for each week
declare -A month_dirs # Tracks most recent directory for each month

function age_in_days() {
    local dir=$1
    local modification_date=$(date -r "$dir" +%s)
    echo $(( ($current_date - $modification_date) / 86400 ))
}

function age_in_weeks() {
    local dir=$1
    echo $(( $(age_in_days "$dir") / 7 ))
}

function month_number() {
    local dir=$1
    echo $(date -r "$dir" +%Y%m)
}

function mark_directories() {
    local dir=$1
    local age_days=$(age_in_days "$dir")
    local age_weeks=$(age_in_weeks "$dir")
    local month_num=$(month_number "$dir")
    local dir_mod_date=$(date -r "$dir" +%s) # Modification date of the current directory

    # Mark directories for daily backups
    if [ $age_days -le $daily_backup_days ]; then
        keep_dirs["$dir"]=1
    fi

    # Mark directories for weekly backups, retaining the most recent directory per week
    if [ $age_weeks -gt 0 ] && [ $age_weeks -le $weekly_backup_weeks ]; then
        # Get the modification date of the directory already stored for the same week.
        local current_week_mod_date=$(date -r "${week_dirs[$age_weeks]}" +%s 2>/dev/null)
        if [ -z "$current_week_mod_date" ] || [ $current_week_mod_date -lt $dir_mod_date ]; then
            # If the directory currently being examined is newer updates the entry for that week in the week_dirs associative array to point to this directory.
            # We'll add directory name to "keep_dirs" array later on and mark for retention.
            week_dirs[$age_weeks]="$dir"
        fi
    fi

    # Mark directories for monthly backups, retaining the most recent directory per month
    if [ $(date -d "-$monthly_backup_months months" +%Y%m) -le $month_num ]; then
        local current_month_mod_date=$(date -r "${month_dirs[$month_num]}" +%s 2>/dev/null)
        if [ -z "$current_month_mod_date" ] || [ $current_month_mod_date -lt $dir_mod_date ]; then
            month_dirs[$month_num]="$dir"
        fi
    fi
}

# Iterate over the backup directory and mark directories for retention
for dir in "$backup_folder"/*/; do
    mark_directories "$dir"
done

# Add directories selected for weekly and monthly retention to the keep_dirs array
for dir in "${week_dirs[@]}" "${month_dirs[@]}"; do
    keep_dirs["$dir"]=1
done

# Output the list of directories marked for retention
echo -e "${GREEN}Directories to be kept:${NC}"
for dir in "${!keep_dirs[@]}"; do
    if [ ${keep_dirs["$dir"]} -eq 1 ]; then
        echo -e "${YELLOW}$dir"
    fi
done | sort

# Remove directories that are not marked for retention
for dir in "$backup_folder"/*/; do
    if [ -z "${keep_dirs["$dir"]}" ] || [ ${keep_dirs["$dir"]} -eq 0 ]; then
        echo -e "${RED}Removing ${NC}$dir"
        rm -rf "$dir"
    fi
done
