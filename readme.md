```bash
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
```
