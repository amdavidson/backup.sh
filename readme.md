```bash
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
```
