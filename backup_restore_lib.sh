# This is a backup and restore function library #
#################################################

# backup.sh functions

# A function to validate backup.sh 3 inputed params
validate_backup_params() {

    # Check if the backup script was called with --help
    if [[ "$*" == *"--help"* ]] || [ "$#" -eq 0 ]; then
	echo "Usage: $0 <source_dir> <backup_dir> <encryption_key> <days>"
    	echo ""
    	echo "Description:"
    	echo "  This script securely backs up a specified directory by creating compressed tar files"
    	echo "  for each subdirectory and individual files. The backup is encrypted using GPG and"
    	echo "  then copied to a remote server."
    	echo ""
    	echo "Parameters:"
    	echo "  <source_dir>: The directory to be backed up."
    	echo "  <backup_dir>: The destination directory for storing the encrypted backup."
    	echo "  <encryption_key>: The key used for encrypting the source directory and decrypting"
    	echo "                    the encrypted backup. Choose a strong passphrase for security."
    	echo "  <days>: The number of days (n) to consider for backing up only files modified"
    	echo "          within the last n days. This helps in creating incremental backups."
    	echo ""
    	echo "Example:"
    	echo "  $0 /path/to/source /path/to/backup my_secure_key 7"
    	echo ""
    	echo "NOTE: None of the 4 parameters used in this command can start with '#'"
    	exit 0
    fi

    # Validate the parameters inputed
    if [ "$#" -ne 4 ]; then
        echo "Error: Invalid number of parameters. Usage: $0 <source_dir> <backup_dir> <encryption_key> <days>"
	echo "You can use '--help' to get help messages on how to use this command "
        exit 1
    fi

    source_dir="$1"
    backup_dir="$2"
    encryption_key="$3"
    days="$4"

    # Validate source_dir
    if [ ! -e "$source_dir" ] && [ $(id -u) -eq 0 ]; then
        echo "Error: Source directory '$source_dir' does not exist."
        exit 1
    elif [ ! -e "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist, or Permission Denied to access it."
	exit 1
    elif [ ! -d "$source_dir" ]; then
        echo "Error: '$source_dir' is not a directory."
        exit 1
    elif [ ! -r "$source_dir" ]; then
        echo "Error: Permission Denied to access '$source_dir'"
        exit 1
    fi

    # Validate backup_dir
    if [ ! -e "$backup_dir" ] && [ $(id -u) -eq 0 ]; then
        echo "Error: Backup directory '$backup_dir' does not exist."
        exit 1
    elif [ ! -e "$backup_dir" ]; then
        echo "Error: Backup directory '$backup_dir' does not exist, or Permission Denied to access it."
        exit 1
    elif [ ! -d "$backup_dir" ]; then
        echo "Error: '$backup_dir' is not a directory."
        exit 1
    elif [ ! -r "$backup_dir" ]; then
        echo "Error: Permission Denied to access '$backup_dir'"
        exit 1
    fi

    # Validate days is numeric
    if [[ ! $4 =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
    	echo "Error: The days parameter '$4' is not a numeric value."
	exit 1
    fi
}

# A function to perform the backup part
backup() {

    # Backup logic
    source_dir="$1"
    backup_dir="$2"
    encryption_key="$3"
    days="$4"

    # Create a variable to check created archive
    updated_count=0

    # Create a unique timestamp
    timestamp=$(date +"%Y_%m_%d_%H_%M_%S")

    # Make sure source_dir is in the right format (ends with /)
    if [[ "$source_dir" != */ ]]; then
        source_dir="$source_dir/"
    fi

    # Make sure backup_dir is in the right format (ends with /)
    if [[ "$backup_dir" != */ ]]; then
        backup_dir="$backup_dir/"
    fi

    # Create a directory for the backup
    backup_directory="$backup_dir$timestamp"
    mkdir -p "$backup_directory"

    # Loop over directories and backup modified files
    for dir in "$source_dir"*; do
        if [ -d "$dir" ]; then
            last_modified=$(find "$dir" -type f -mtime -$days -print)
            if [ -n "$last_modified" ]; then
                find "$dir" -type f -mtime -$days -exec basename {} \; | tar -czf "$backup_directory/$(basename "$dir")_$timestamp.tgz" -C "$dir" -T - &>/dev/null
                gpg --symmetric --s2k-cipher-algo AES256 --s2k-count 65536 --output "$backup_directory/$(basename "$dir")_$timestamp.gpg" --batch --passphrase-fd 0 < <(echo "$encryption_key") "$backup_directory/$(basename "$dir")_$timestamp.tgz"
                rm "$backup_directory/$(basename "$dir")_$timestamp.tgz"
		((updated_count++))
            fi
        fi
    done

    # Point out to the first iteration in the loop
    first_iteration=true

    # Group all files in the source directory one by one into one .tar file
    for file in "$source_dir"*; do
        if [ -f "$file" ]; then
            last_modified=$(find "$source_dir" -type f -mtime -$days -print)
            if [[ $last_modified == *"$file"* ]]; then
                if [ "$first_iteration" = true ]; then
                        basename "$file" | tar -cf "$backup_directory/files_$timestamp.tar" -C "$source_dir" -T - &>/dev/null
                        first_iteration=false
                else
                        basename "$file" | tar -uf "$backup_directory/files_$timestamp.tar" -C "$source_dir" -T - &>/dev/null
                fi
            fi
        fi
    done

    # Compress the tar file using gzip into .tgz file
    if [ -e "$backup_directory/files_$timestamp.tar" ]; then
	gzip "$backup_directory/files_$timestamp.tar"
	mv "$backup_directory/files_$timestamp.tar.gz" "$backup_directory/files_$timestamp.tgz"
        gpg --symmetric --s2k-cipher-algo AES256 --s2k-count 65536 --output "$backup_directory/files_$timestamp.gpg" --batch --passphrase-fd 0 < <(echo "$encryption_key") "$backup_directory/files_$timestamp.tgz"
        rm "$backup_directory/files_$timestamp.tgz"
	((updated_count++))
    fi

    # Check if there were no changes in the past number of days inputed 
    if [ "$updated_count" = "0" ]; then
    	echo "*** No files have been changed since $4 days ***"
	echo "       *** The Backup is not needed ***"
        rm -rf "$backup_directory"
        exit 0
    fi

    # Prints out that the backup locally has been completed
    echo "✅ Local Backup has been completed successfully!"

    # Copy the backup to a remote server using scp
    ## make sure to modifiy 'user@remote_server:/path/to/backup/destination/' to match your usecase
    ## you should run 'ssh-copy-id user@remote_server' once before this script to make sure scp works
    scp -qB -r "$backup_directory" user@remote_server:/path/to/backup/destination/ &>/dev/null

    # Check if copying the backup to a remote server is successful
    if [ $? -ne 0 ]; then
            echo "⚠️  copying the backup to a remote server failed!!"
	    exit 1
    else
	    echo "✅ Copying Backup to remote server succeeded!"
	    exit 0
    fi

}

########################################################################################################################################################
########################################################################################################################################################
# restore.sh functions

# A function to validate restore.sh 3 inputed params
validate_restore_params() {

    # Check if the restore script was called with --help
    if [[ "$*" == *"--help"* ]] || [ "$#" -eq 0 ]; then
        echo "Usage: $0 <backup_dir> <restore_dir> <decryption_key>"
    	echo ""
    	echo "Description:"
    	echo "  This script restores a previously encrypted backup to the specified directory."
    	echo ""
    	echo "Parameters:"
    	echo "  <backup_dir>: The directory containing the backup you want to restore."
    	echo "  <restore_dir>: The destination directory for restoring the backup."
    	echo "  <decryption_key>: The key used for decrypting the backup and restoring its contents."
    	echo "                    Ensure you provide the correct decryption key used during the backup."
    	echo ""
    	echo "Example:"
    	echo "  $0 /path/to/backup /path/to/restore my_secure_key"
    	echo ""
    	echo "NOTE: None of the 3 parameters used in this command can start with '#'"
    	exit 0
    fi

    # Validate the parameters inputed
    if [ "$#" -ne 3 ]; then
        echo "Error: Invalid number of parameters. Usage: $0 <backup_dir> <restore_dir> <decryption_key>"
        echo "You can use '--help' to get help messages on how to use this command "
	exit 1
    fi

    backup_dir="$1"
    restore_dir="$2"
    decryption_key="$3"

    # Validate backup_dir
    if [ ! -e "$backup_dir" ] && [ $(id -u) -eq 0 ]; then
        echo "Error: Backup directory '$backup_dir' does not exist."
        exit 1
    elif [ ! -e "$backup_dir" ]; then
        echo "Error: Backup directory '$backup_dir' does not exist, or Permission Denied to access it."
        exit 1
    elif [ ! -d "$backup_dir" ]; then
        echo "Error: '$backup_dir' is not a directory."
        exit 1
    elif [ ! -r "$backup_dir" ]; then
        echo "Error: Permission Denied to access '$backup_dir'"
        exit 1
    fi

    # Validate restore_dir
    if [ ! -e "$restore_dir" ] && [ $(id -u) -eq 0 ]; then
        echo "Error: Restore directory '$restore_dir' does not exist."
        exit 1
    elif [ ! -d "$restore_dir" ]; then
        echo "Error: Restore directory '$restore_dir' does not exist, or Permission Denied to access it."
        exit 1
    elif [ ! -d "$restore_dir" ]; then
        echo "Error: '$restore_dir' is not a directory."
        exit 1
    elif [ ! -r "$restore_dir" ]; then
        echo "Error: Permission Denied to access '$restore_dir'"
        exit 1
    fi

    # Validate encrypted files in backup_dir
    if [ -n "$(find "$backup_dir" -maxdepth 1 -type f ! -name "*.gpg" -print -quit)" ]; then
        echo "Warning: Backup directory '$backup_dir' contains files with invalid extensions, only '.gpg' is expected"
	echo "*** Discarding these files ***"
    fi
    if [ -z "$(find "$backup_dir" -maxdepth 1 -type f -name "*.gpg" -print -quit)" ]; then
        echo "Error: Backup directory '$backup_dir' contains no encrypted files with '.gpg' extension."
	echo "⚠️  Restore failed!!"
	exit 1
    fi
}

# A function to perform the restore part
restore() {

    # Restore logic
    backup_dir="$1"
    restore_dir="$2"
    decryption_key="$3"

    # Make sure backup_dir is in the right format (ends with /)
    if [[ "$backup_dir" != */ ]]; then
        backup_dir="$backup_dir/"
    fi

    # Make sure restore_dir is in the right format (ends with /)
    if [[ "$restore_dir" != */ ]]; then
        restore_dir="$restore_dir/"
    fi

    # Create a temp directory for restoring
    temp_dir=""$restore_dir"temp_restore"
    mkdir -p "$temp_dir"

    # Loop over encrypted files in the backup directory and decrypt them
    for encrypted_file in "$backup_dir"*.gpg; do
        encrypted_file_name=$(echo "$encrypted_file" | sed 's/\.gpg$//')
        gpg --decrypt --batch --passphrase-fd 0 --output "$temp_dir/$(basename "$encrypted_file_name".tgz)" < <(echo "$decryption_key") "$encrypted_file" &>/dev/null
	if [ $? -ne 0 ]; then
		echo "Error: The Decryption Key: '$decryption_key' is incorrect"
		echo "⚠️  Restore failed!!"
		rm -r "$temp_dir"
		exit 1
	fi
    done

    # Loop over decrypted files in the temp directory and extract them
    for decrypted_file in "$temp_dir"/*; do
        decrypted_file_name=$(basename "$decrypted_file" | sed 's/_\([0-9]\{4\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}_[0-9]\{2\}\)\.tgz$//')
	if [[ "$decrypted_file_name" =~ "files" ]]; then
                tar -xzf "$decrypted_file" -C "$restore_dir"
        else
                mkdir -p "$restore_dir$decrypted_file_name"
                tar -xzf "$decrypted_file" -C "$restore_dir$decrypted_file_name"
        fi
    done

    # Clean up temp directory
    rm -r "$temp_dir"

    # Show the user the Backup has been successful
    echo "✅ Restore has been completed successfully!"
}
