#!/bin/bash

# Validation of inputs upfront
if [ "$ENABLE_RESTORE" != "true" ]; then
    echo "Restoration was not enabled. Exiting Gracefully."
    exit 0
fi

if [ -z $S3_BUCKET_BACKUP_PATH ]; then
    echo "You must specify a S3_BUCKET_BACKUP_PATH such as s3://my-backups/my-backup.tar.gz"
    exit 1
fi

if [ -z $BACKUP_SET_DIR ] ; then
    echo "*********************************************************************************************"
    echo "* You have not specified BACKUP_SET_DIR -- this means that if your archive set uncompresses *"
    echo "* to a different directory than the file is named, this restore may fail                    *"
    echo "* See logs below to ensure the right path was selected.                                     *"
    echo "*********************************************************************************************"
fi

if [ -z $PURGE_ON_COMPLETE ]; then
    PURGE_ON_COMPLETE=true
fi

echo "=============== Neo4j Restore ==============================="
echo "Beginning restore process"
echo "S3_BUCKET_BACKUP_PATH=$S3_BUCKET_BACKUP_PATH"
echo "BACKUP_SET_DIR=$BACKUP_SET_DIR"
echo "FORCE_OVERWRITE=$FORCE_OVERWRITE"
ls /data/databases
echo "============================================================"

if [ -d "/data/databases/neo4j" ] ; then
    echo "You have an existing neo4j database at /data/databases/neo4j"

    if [ "$FORCE_OVERWRITE" != "true" ] ; then
        echo "And you have not specified FORCE_OVERWRITE=true, so we will not restore because"
        echo "that would overwrite your existing data.   Exiting.".
        exit 0;
    fi
else 
    echo "No existing neo4j database found at /data/databases/neo4j"
fi

# Pass the force flag to the restore operation, which will overwrite
# whatever is there, if and only if FORCE_OVERWRITE=true.
if [ "$FORCE_OVERWRITE" = true ]; then
    echo "We will be force-overwriting any data present"
    FORCE_FLAG="--force"
else
    # Pass no flag in any other setup.
    echo "We will not force-overwrite data if present"
    FORCE_FLAG=""
fi

RESTORE_ROOT=/data/backupset

echo "Making restore directory"
mkdir -p "$RESTORE_ROOT"

echo "Copying $S3_BUCKET_BACKUP_PATH -> $RESTORE_ROOT"

aws s3 cp "$S3_BUCKET_BACKUP_PATH" "$RESTORE_ROOT"

echo "Backup size pre-uncompress:"
du -hs "$RESTORE_ROOT"
ls -l "$RESTORE_ROOT"

# Important note!  If you have a backup name that is "foo.tar.gz" or 
# foo.zip, we need to assume that this unarchives to a directory called
# foo, as neo4j backup sets are directories.  So we'll remove the suffix
# after unarchiving and use that as the actual backup target.
BACKUP_FILENAME=$(basename "$S3_BUCKET_BACKUP_PATH")
RESTORE_FROM=uninitialized
if [[ $BACKUP_FILENAME =~ \.tar\.gz$ ]] ; then
    echo "Untarring backup file"
    cd "$RESTORE_ROOT" && tar --force-local --overwrite -zxvf "$BACKUP_FILENAME"

    if [ $? -ne 0 ] ; then
        echo "Failed to unarchive target backup set"
        exit 1
    fi

    # foo.tar.gz untars/zips to a directory called foo.
    UNTARRED_BACKUP_DIR=${BACKUP_FILENAME%.tar.gz}

    if [ -z $BACKUP_SET_DIR ] ; then
        echo "BACKUP_SET_DIR was not specified, so I am assuming this backup set was formatted by my backup utility"
        RESTORE_FROM="$RESTORE_ROOT/backup/$UNTARRED_BACKUP_DIR"
    else 
        RESTORE_FROM="$RESTORE_ROOT/$BACKUP_SET_DIR"
    fi
elif [[ $BACKUP_FILENAME =~ \.zip$ ]] ; then
    echo "Unzipping backupset"
    cd "$RESTORE_ROOT" && unzip -o "$BACKUP_FILENAME"
    
    if [ $? -ne 0 ]; then 
        echo "Failed to unzip target backup set"
        exit 1
    fi

    # Remove file extension, get to directory name  
    UNZIPPED_BACKUP_DIR=${BACKUP_FILENAME%.zip}

    if [ -z $BACKUP_SET_DIR ] ; then
        echo "BACKUP_SET_DIR was not specified, so I am assuming this backup set was formatted by my backup utility"
        RESTORE_FROM="$RESTORE_ROOT/backup/$UNZIPPED_BACKUP_DIR"
    else
        RESTORE_FROM="$RESTORE_ROOT/$BACKUP_SET_DIR"
    fi
else
    # If user stores backups as uncompressed directories, we would have pulled down the entire directory
    echo "This backup $BACKUP_FILENAME looks uncompressed."
    RESTORE_FROM="$RESTORE_ROOT/$BACKUP_FILENAME"
fi

echo "BACKUP_FILENAME=$BACKUP_FILENAME"
echo "UNTARRED_BACKUP_DIR=$UNTARRED_BACKUP_DIR"
echo "UNZIPPED_BACKUP_DIR=$UNZIPPED_BACKUP_DIR"
echo "RESTORE_FROM=$RESTORE_FROM"

echo "Set to restore from $RESTORE_FROM"
echo "Post uncompress backup size:"
ls -al "$RESTORE_ROOT"
du -hs "$RESTORE_FROM"

echo "Unbinding from cluster"
neo4j-admin unbind

cd /data && \
echo "Dry-run command"
echo neo4j-admin restore \
    --from="$RESTORE_FROM/neo4j" \
    --database=neo4j $FORCE_FLAG

# This data is output because of the way neo4j-admin works.  It writes the restored set to
# /var/lib/neo4j by default.  This can fail if volumes aren't sized appropriately, so this 
# aids in debugging.
echo "Volume mounts and sizing"
df -h

echo "Now restoring"
neo4j-admin restore \
    --from="$RESTORE_FROM/neo4j" \
    --database=neo4j $FORCE_FLAG

RESTORE_EXIT_CODE=$?

if [ "$RESTORE_EXIT_CODE" -ne 0 ]; then 
    echo "Restore process failed; will not continue"
    exit $RESTORE_EXIT_CODE
else
    echo "Restoration succeeded"
fi

# echo "Rehoming database"
# echo "Restored to:"
# ls -l /var/lib/neo4j/data/databases

# # neo4j-admin restore puts the DB in the wrong place, it needs to be re-homed
# # for docker.
# mkdir /data/databases

# # Danger: here we are destroying previous data.
# # Optional: you can move the database out of the way to preserve the data just in case,
# # but we don't do it this way because for large DBs this will just rapidly fill the disk
# # and cause out of disk errors.
# if [ -d "/data/databases/neo4j" ] ; then
#    if [ "$FORCE_OVERWRITE" = "true" ] ; then
#       echo "Removing previous database because FORCE_OVERWRITE=true"
#       rm -rf /data/databases/neo4j
#    fi
# fi

# mv /var/lib/neo4j/data/databases/neo4j /data/databases/

# Modify permissions/group, because we're running as root.
# Neo4j user id is 101 on the official docker image
chown -R 101:101 /data/databases
chgrp -R 101:101 /data/transactions

echo "Final permissions"
ls -al /data/databases/neo4j

echo "Final size"
du -hs /data/databases/neo4j

if [ "$PURGE_ON_COMPLETE" = true ] ; then
    echo "Purging backupset from disk"
    rm -rf "$RESTORE_ROOT"
fi

exit $RESTORE_EXIT_CODE