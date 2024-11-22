In order to use the backup script:

First specify which directory exactly you want to backup
After that, specify the destination directory where you want the backup to be stored at
Provide the encryption key
Finally specify the last number of days you want to search for modified files in

Example for the backup script:

/path/to/the/backup <source_dir> <dest_dir> <encryption_key> <numberofdays>

It has to be written in that exact format and order.


In order to use the restore script:

For the first parameter you will have to specify the backup directory you want to 
restore the back up from, keep in mind that if that backup directory is not backedup
by the backup script first, it will not work, also do not forget to add the date that
you want to to restore from after the backup directory.

Example for the restore script:

/path/to/the/restore <backup_directory/Date_of_backup> <restore_dir> <decryption_key>



