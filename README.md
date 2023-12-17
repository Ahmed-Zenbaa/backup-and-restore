Backup & Restore Tool:

The Backup & Restore Tool is a command-line utility designed to simplify and automate the process of creating 
and restoring backups for specified directories. It provides encryption for added security during the backup process.

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Dependencies:

-Ensure that the following dependencies are installed on your system:

    tar: Download and Install tar
    gzip: Download and Install gzip
    GPG (GNU Privacy Guard): Download and Install GPG


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Description:


-Files and steps:

	There are 5 files in the tar file:
		backup_restore_lib.sh              	# contains functions for the backup.sh and restore.sh
		backup.sh				# the executable script to run backup script
		restore.sh				# the executable script to run restore script
		design_document			# the file that includes all your design decisions and assumptions
		README.md				# the file explaining how to use your backup tool
	
	steps:
	
	- go the folder where you downloaded Ahmed_Zenbaa_Devops_Task.tgz file
	>>>	tar -xvzf Ahmed_Zenbaa_Devops_Task.tgz
	>>>	cd Ahmed_Zenbaa_Devops_Task/
	>>>	chmod +x backup.sh restore.sh
	- now you are ready to use the scripts
	- the backup.sh and restore.sh can be executed from any where as long as you enter their absolute or relative path correctly
		
	
-Backup script:

	Usage:
	./backup.sh <source_dir> <backup_dir> <encryption_key> <days>

	Description:
	This script securely backs up a specified directory by creating compressed tar files
	for each subdirectory and individual files. The backup is encrypted using GPG and 
	then copied to a remote server.
	
	Parameters:
	<source_dir>: The directory to be backed up.
	<backup_dir>: The destination directory for storing the encrypted backup.
	<encryption_key>: The key used for encrypting the source directory and decrypting
			   the encrypted backup. Choose a strong passphrase for security.
	<days>: The number of days (n) to consider for backing up only files modified"
	        within the last n days. This helps in creating incremental backups.
	
	Example:"
        ./backup.sh /path/to/source /path/to/backup my_secure_key 7




-Restore script:

	Usage:
	./restore.sh <backup_dir> <restore_dir> <decryption_key>

	Description:
	This script restores a previously encrypted backup to the specified directory.
	
	Parameters:
	<backup_dir>: The directory containing the backup you want to restore.
	<restore_dir>: The destination directory for restoring the backup.
	<decryption_key>: The key used for decrypting the backup and restoring its contents.
	Ensure you provide the correct decryption key used during the backup.
	
	Example:"
        ./restore.sh /path/to/backup /path/to/restore my_secure_key





Note: None of the parameters used in either commands can start with '#'

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Details:

- a help message witha description of the script is inputed if the user use the script with no parameters
  , or if he uses '--help'
- All possible errors and problems while running either scripts are handled to the best of my capability.
- The errors include:
	- checking the number of parameters required for each script.
	- checking if the directories inputed exist.
	- checking if the user inputed directories nd not file names by mistake.
	- checking if the user has acces to the inputed directories.
	- checking if the user inputed a numeric value for the number of days.
	- checking if there is any files in the wanted backup directory to backup that has been changed since the specified number of days.
	- checking if the backup to a remote server failed.
	- checking if the directory you want to restore from include '.gpg' files.
	- checking if the decryption key when restoring is the same asthe encryption key used when backing-up.
- The User is presented with descriptive error messages for each error.
- The user is presented with a success message if the scripts runs successfully.
- The user is presented with a message stating that no backup is neede when there are no files matching the days parameter he inputted.


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

- Read 'design_document.md' to get to know my design decisions

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




