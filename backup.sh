#!/usr/bin/env bash

print_logo () {
cat <<'EOF'
 _                _                     _     
| |__   __ _  ___| | ___   _ _ __   ___| |__  
| '_ \ / _` |/ __| |/ / | | | '_ \ / __| '_ \ 
| |_) | (_| | (__|   <| |_| | |_) |\__ \ | | |
|_.__/ \__,_|\___|_|\_\\__,_| .__(_)___/_| |_|
                            |_|               

A wrapper around restic to help control configuration.
EOF
# Copyright (c) 2021 Andrew Davidson
}

print_help () {
    echo -e """
    Usage:
    backup.sh 'command' 'destination' 'input'
    
    Supported Commands:
    backup        - initiate a backup of the home folder to the destination
    check         - check repository for consistency
    clean         - clean (prune) extra files from the repository
    find          - find a file by a string in the repository (requires input)
                    ex: backup.sh find s3 critical_file.doc
    help          - print this help
    init          - intiialize a new backup repository
    mount         - mount repository as a local file system
                    ex: backup.sh mount s3 /mnt/restic
    prune         - prune old backups on the destination
    restore       - restores file from repository (requires input)
                    ex: backup.sh restore s3 latest --target=/tmp/restore --include=/home/user/Documents
    snapshots     - list backups on the destination
    stats         - print statistics about the backup repository
    unlock        - unlock a locked repository - use for stale locks

    Required Configuration: 
    \$XDG_CONFIG_HOME/backup.sh/\$DESTINATION/\$DESTINATION.repo 
    - Define the repository path in this file

    \$XDG_CONFIG_HOME/backup.sh/\$DESTINATION/\$DESTINATION.pwd
    - Define the repository password in this file

    \$XDG_CONFIG_HOME/backup.sh/\$DESTINATION/\$DESTINATION.paths
    - list of paths to be backed up

    \$XDG_CONFIG_HOME/backup.sh/\$DESTINATION/\$DESTINATION.exclude
    - list of paths to be excluded

    \$XDG_CONFIG_HOME/backup.sh/\$DESTINATION/\$DESTINATION.keys
    - OPTIONAL: bash exports of required keys for s3/b2 backups

    \$XDG_DATA_HOME/backup.sh/\$DESTINATION/\$DESTINATION.log
    - empty file for logging

    

    """
}

print_and_log () {
    /usr/bin/ts "%Y-%m-%dT%H:%M:%S" | /usr/bin/tee -a $BACKUP_LOG
}

set -o errexit
set -o pipefail

ACTION=$1
DESTINATION=$2
INPUT="${@:3}"

if [[ -z $DESTINATION && $ACTION == "help" ]]; then
    print_logo
    print_help
elif [[ -z $DESTINATION ]]; then
    echo "Destination must not be blank"
    print_help
else

    if [[ -f "$XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.repo" ]]; then
        BACKUP_REPOSITORY=$(cat $XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.repo)
    else 
        echo "Must configure repository at $XDG_CONFIG_HOME/backup.sh/$DESTINATION"
        print_help
        exit 2
    fi
    if [[ -f "$XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.keys" ]]; then
        source "$XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.keys"
    fi
    BACKUP_PASSWORD="$XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.pwd"
    BACKUP_EXCLUDE_FILE="$XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.exclude"
    BACKUP_PATHS="$XDG_CONFIG_HOME/backup.sh/$DESTINATION/$DESTINATION.paths"
    BACKUP_LOG="$XDG_DATA_HOME/backup.sh/$DESTINATION/$DESTINATION.log"

    if [[ -f "/sys/class/power_supply/AC/online" ]]; then
        AC_POWER=$(cat /sys/class/power_supply/AC/online)
    else
        AC_POWER=1
    fi


    case $ACTION in
        "backup")
            if [[ $AC_POWER == 1 ]]; then
                echo "backing up to $DESTINATION." | print_and_log
                /usr/bin/restic \
                    -r "$BACKUP_REPOSITORY" \
                    -p "$BACKUP_PASSWORD" \
                    --cleanup-cache \
                    --exclude-caches \
                    --exclude-file="$BACKUP_EXCLUDE_FILE" \
                    --files-from="$BACKUP_PATHS" \
                    --verbose \
                    backup | print_and_log 
            else
                echo "not plugged in, canceling backup."
            fi
            ;;
        "check")
            echo "Checking backup repository at $DESTINATION" | print_and_log
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                check | print_and_log
            ;;
        "find")
            echo "Searching for $INPUT at $DESTINATION" 
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                find $INPUT 
            ;;
        "help")
            print_logo
            print_help
            ;;
        "init")
            echo "Initializing backup repository at $DESTINATION" | print_and_log
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                init | print_and_log
            ;;
        "mount")
            echo "Mounting backup repository $DESTINATION at $INPUT" | print_and_log
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                mount "$INPUT" | print_and_log
            ;;
        "restore")
            echo "Restoring from $DESTINATION, $INPUT" | print_and_log
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                restore $INPUT | print_and_log 
            ;;
        "snapshots")
            echo "Listing snapshots on $DESTINATION"
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                snapshots 
            ;;
        "stats")
            echo "Printing statistics for $DESTINATION"
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                stats 
            ;;
        "prune")
            if [[ $AC_POWER == 1 ]]; then
                echo """
                Pruning backups at $DESTINATION ...
                Keeping:
                - 24 hourly backups
                - 90 daily backups
                - 12 monthly backups
                - 5  yearly backups
                """ | print_and_log
                /usr/bin/restic \
                    -r "$BACKUP_REPOSITORY" \
                    -p "$BACKUP_PASSWORD" \
                    --verbose \
                    --prune \
                    --keep-hourly=24 \
                    --keep-daily=90 \
                    --keep-monthly=12 \
                    --keep-yearly=5 \
                    forget | print_and_log
            else
                echo "Not plugged in, canceling prune."
            fi
            ;;
        "unlock")
            echo "Unlocking backup repository at $DESTINATION" | print_and_log
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                unlock | print_and_log
            ;;
        "clean")
            echo "Cleaning repository at $DESTINATION" | print_and_log
            /usr/bin/restic \
                -r "$BACKUP_REPOSITORY" \
                -p "$BACKUP_PASSWORD" \
                --verbose \
                prune | print_and_log
            ;;
        *)
            echo "Action: $ACTION not recognized."
            print_help
            ;;
    esac
fi
