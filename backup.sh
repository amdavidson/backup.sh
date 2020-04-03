#!/usr/bin/env bash

print_logo () {
cat <<'EOF'
 _                _                     _     
| |__   __ _  ___| | ___   _ _ __   ___| |__  
| '_ \ / _` |/ __| |/ / | | | '_ \ / __| '_ \ 
| |_) | (_| | (__|   <| |_| | |_) |\__ \ | | |
|_.__/ \__,_|\___|_|\_\\__,_| .__(_)___/_| |_|
                            |_|               
EOF
# Copyright (c) 2020 Andrew Davidson
}

print_help () {
    echo -e """
    Usage:
    backup.sh 'command' 'destination'
    
    Supported Commands:
    backup        - initiate a backup of the home folder to the destination
    list          - list backups on the destination
    prune         - prune old backups on the destination
    
    Supported destinations:
    royal         - local borg/SFTP backup to Royal
    wasabi        - remote restic backup to Wasabi
    """
}


set -o errexit
set -o pipefail

ACTION=$1
DESTINATION=$2


###
# ~/.env should contain these variables:
#
#    ## Borg Royal Environment
#    export BORG_PASSPHRASE=
#
#    ## Restic Wasabi Environment
#    export AWS_ACCESS_KEY_ID=
#    export AWS_SECRET_ACCESS_KEY=
#    export RESTIC_REPOSITORY=s3:s3.wasabisys.com/backup
#    export RESTIC_PASSWORD=
###
source ~/.env 

###
# For the borg backup to work properly, the backup host should be 
# configured in `$HOME/.ssh/config`:
#     Host backup
#        Hostname backup.hostname
#        Port 22
#        User backupuser
###


case $DESTINATION in
    "royal")
        case $ACTION in
            "backup")
                if on_ac_power; then
                    borg create  \
                        --exclude $HOME/backups \
                        --exclude $HOME/tmp \
                        --exclude $HOME/Downloads \
                        --exclude $HOME/Desktop \
                        --exclude $HOME/.cache \
                        --exclude $HOME/.local/gnome-boxes \
                        backup:/bkup/$(hostname)::$(date '+%s') \
                        $HOME
                else
                    echo "Not plugged in, canceling backup."
                fi
                ;;
            "check")
                borg check backup:/bkup/$(hostname)
                ;;
            "list")
                borg list backup:/bkup/$(hostname)
                ;;
            "prune")
                echo """
                Pruning $DESTINATION backups...
                Keeping:
                - 24 hourly backups
                - 90 daily backups
                - 12 monthly backups
                - 5  yearly backups
                """
                borg prune \
                    --stats --list \
                    --keep-hourly 24 \
                    --keep-daily 90 \
                    --keep-monthly 12 \
                    --keep-yearly 5 \
                    backup:/bkup/$(hostname)
                ;;
            "help")
                print_logo
                print_help
                ;;
            *)
                echo "Action: $ACTION not recognized."
                print_help
                ;;
        esac
        ;;
    "wasabi")
        case $ACTION in
            "backup")
                if on_ac_power; then
                    restic backup \
                        --quiet \
                        --exclude $HOME/backups \
                        --exclude $HOME/tmp \
                        --exclude $HOME/Desktop \
                        --exclude $HOME/Downloads \
                        --exclude $HOME/.cache \
                        --exclude $HOME/.cargo \
                        --exclude $HOME/.local/share/gnome-boxes \
                        $HOME
                else
                    echo "Not plugged in, canceling backup."
                fi
                ;;
            "check")
                restic check
                ;;
            "list")
                restic snapshots
                ;;
            "prune")
                echo """
                Pruning $DESTINATION backups...
                Keeping:
                - 90 daily backups
                - 12 monthly backups
                - 5  yearly backups
                """

                restic forget --prune \
                    --keep-hourly 4 \
                    --keep-daily 90 \
                    --keep-monthly 12 \
                    --keep-yearly 5

                ;;
            "help")
                print_logo
                print_help
                ;;
            *)
                echo "Action: $ACTION not recognized."
                print_help
                ;;
        esac
        ;;
    *)
        if [[ -z $DESTINATION && $ACTION == "help" ]]; then
            print_logo
            print_help
        else
            echo "Destination: $DESTINATION not recognized."
            print_help
        fi
        ;;
esac

