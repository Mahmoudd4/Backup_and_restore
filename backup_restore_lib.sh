#!/bin/bash

# Validate backup parameters

validate_backup_params() {

    # Making sure the user entered the 4 parameters we need
    if [ $# -ne 4 ]; then
        echo " Please enter the correct number of paramaters, example:
	./backup.sh <source_dir> <dest_dir> <encryption_key> <days>"
        exit 1
    fi
    # Cheking to see if soruce directory exists
    if [ ! -d "$1" ]; then
        echo "Source directory does not exist"
        exit 1
    fi
    # Checking to see if backup directory exists
    if [ ! -d "$2" ]; then
        echo "Destination directory does not exist"
        exit 1
    fi
}


backup(){

	# Storing the date in a bash variable
        DATE=$(date "+%Y-%m-%d_%H-%M-%S")
        # Making the date directory
        DATE_DIR="${DEST_DIR}/${DATE}"
        mkdir -p "${DATE_DIR}"
	# Creating a hidden file to validate the backup directory when restoring
	touch "${DATE_DIR}/.backup_meta"
        # Looping over the source directory 
        for i in "${SOURCE_DIR}"/*; do
                # If it is a directory then
                if [ -d "$i" ]; then
                         DIR_NAME=$(basename "$i") # Getting the dir name only
                         if find "$i" -type f -mtime -${DAYS} | grep -q .; then
                                 TAR_FOR_EACH_DIR="${DATE_DIR}/${DIR_NAME}_${DATE}.tgz"
                                 # Finding the files modified within the entered number of days
                                 find "$i" -mtime -${DAYS} -type f | tar -czf "${TAR_FOR_EACH_DIR}" -T -
                                 # Then we will encrypt the tar file with the given passphrase
                                 gpg --symmetric --batch --passphrase "${ENCRYPTION_KEY}" -o "${TAR_FOR_EACH_DIR}.gpg" "${TAR_FOR_EACH_DIR}"
                                 # Then we will remove the unencrypted tar file
                                 rm "${TAR_FOR_EACH_DIR}"
                         fi
                fi
        done

	# Grouping all of the modified files into one final tar file
        FINAL_TAR_FILE="${DATE_DIR}/all_modified_files_${DATE}"
        first=true
	# Change into the DATE_DIR to avoid the decryption for the file with full path
	cd "${DATE_DIR}" || exit 1
        for i in *; do
		if [ "$first" = true ]; then
			# Create tar file for the first file
			tar -cf "${FINAL_TAR_FILE}" "$i"
			first=false
		else 
			# Update the tar file with subsequent files
			tar -uf "${FINAL_TAR_FILE}" "$i"
		fi
	done
	# Compress the tar file using gzip
	gzip "${FINAL_TAR_FILE}"
	# Encrypt the tar.gz file using gpg
	gpg --symmetric --batch --passphrase "${ENCRYPTION_KEY}" -o "${FINAL_TAR_FILE}.tgz.gpg" "${FINAL_TAR_FILE}.gz"
	# Remove the uncompressed tar.gz file
	rm "${FINAL_TAR_FILE}.gz"	
        for i in "${DATE_DIR}"/*.tgz.gpg; do
		if [ "$i" != "${FINAL_TAR_FILE}.tgz.gpg" ]; then
		       rm "$i"
		fi
	done		

}


# Validating the restore parameters
validate_restore_params() {
   if [ ! -f "${BACKUP_DIR}/.backup_meta" ]; then
            echo "Error: This is not a valid backup."
	    echo "Error: Please make sure a BACKUP DATE is specified for restoring which will be found inside the backup directory, USAGE: <BACKUP_DIR/BACKUP_DATE> <RESTORE_DIR>
	    <DECRYPTION_KEY>"
	    echo "Error: Please make sure that this directory is already backed up"
            exit 1
    fi

    if [ $# -ne 3 ]; then
        echo "Please enter the correct number of parameters, example:
        ./restore.sh <backup_dir/date> <restore_dir> <decryption_key>"
        exit 1
    fi

    if [ ! -d "$1" ]; then
        echo "Backup directory does not exist"
        exit 1
    fi

    if [ ! -d "$2" ]; then
        echo "Restore directory does not exist"
        exit 1
    fi
}

restore(){

	# Creating the temp directory under the restore directory
	TEMP_DIR="${RESTORE_DIR}/temp"
	mkdir -p "${TEMP_DIR}"
	# First I have to decrypt the alltarfile in the backup_dir
	cd "${BACKUP_DIR}"
	# To have the file name as a variable
	mytarfile="$(ls)"
	# To remove the .gpg at the end of the filename
	mytarwithoutgpg="${mytarfile%.gpg}"
	# Decrypt the tar file
	gpg --decrypt --batch --passphrase "${DECRYPTION_KEY}" -o "${mytarwithoutgpg}" "${mytarfile}"
	# Now we have decrypted the tar file, now we will extract it in the backup dir
	tar -xzvf "${mytarwithoutgpg}"
	# Now we will remove the tarred file for the all_modified files
	rm "${mytarwithoutgpg}"
        # Now we will loop over the backup directory to decrypt the files and output in the temp dir
	for i in "${BACKUP_DIR}"/*.gpg; do
                # Getting the basename of file only without its path		
		filename=$(basename "$i")
		# Skipping the final tar file which has all the combined files in to avoid duplicate decryption issues
                if [[ "${filename}" == all_modified_files_* ]]; then
			continue
		fi
		# Removing the .gpg from the basefile name for the gpg command
		base_filename="${filename%.gpg}"
		# Using gnupg tool to decrypt the files and store them under the temp directory
		gpg --decrypt --batch --passphrase "$DECRYPTION_KEY" -o "${TEMP_DIR}/${base_filename}" "$i"  #For example if the i is file1.tgz.gpg, the output will be file1.tgz only  
		rm "$i"
	done

	# Looping over the files stored in the temp directory and extracting them one by one under the restore directory
	for x in "${TEMP_DIR}"/*; do
		tar -xzf "$x" -C "${RESTORE_DIR}"
	done

}
