Note: >>> means this is a cli command
       >   means this is a line in a file


Design Decisions:


- The copying of the backup to a remote server part needs modification to match the usecase:
	- I added a dummy remote server with a dummy user and a dummy location to copy to:
>		scp -qB -r "$backup_directory" user@remote_server:/path/to/backup/destination/
	- you must modify this part before running your script.
	- you should copy the public key of the server the script is ran from to the remote server.
>>>		'ssh-copy-id user@remote_server'
	- this will keep the script running smoothly.
	- this part is hard coded into the script as there is no requested parameter for it.
	- you must make sure the <user> , <remote_server> ,and </path/to/backup/destination/> are changed correctlyi to match your usecase.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


- The Crontab to run this backup sccript everyday:
	- you can add to the crontab by using:
		# this is for current user's crontab
>>>		crontab -e

		# this is for user (demo_user)'s crontab #  must be priviliged to run this.
>>>		crontab -e -u demo_user
	
	- you can modify the cron tab to match these configuration:
	#m h dom mon dow   command
	#* *  *   *   *
	#│ │  │   │   │
	#│ │  │   │   └──── Day of the week (0 - 6) (Sunday to Saturday; 7 is also Sunday)
	#│ │  │   └──────── Month (1 - 12)
	#│ │  └──────────── Day of the month (1 - 31)
	#│ └─────────────── Hour (0 - 23)
	#└───────────────── Minute (0 - 59)
	
>		0 2 * * * /loaction/to/backup.sh <source_dir> <backup_dir> <encryption_key> <days>
	
	The crontab expression 0 2 * * * specifies a schedule for a cron job. Breaking it down:

    	0: Minute field. The job will run when the minute is 0 (i.e., the start of the hour).
    	2: Hour field. The job will run when the hour is 2.
    	*: Day of the month field. The job will run on any day of the month.
    	*: Month field. The job will run in any month.
    	*: Day of the week field. The job will run on any day of the week.

	So, in summary, the cron job is scheduled to run every day at 2:00 AM (a suitable time for backups).
	- the <days> parameter should proably be '1' or '1.05' as the archiving and encrypting can take time.


- you can add the cronjob to the crontab in one command line:

>>>		( crontab -l ; echo "0 2 * * * /loaction/to/backup.sh <source_dir> <backup_dir> <encryption_key> <days>" ) | crontab -
	
		# or you can run this cronjob for a diffent user (demo_user) if you are a priviliged user.
>>>		( crontab -u demo_user -l ; echo "0 2 * * * /loaction/to/backup.sh <source_dir> <backup_dir> <encryption_key> <days>" ) | crontab -u demo_user -


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------




