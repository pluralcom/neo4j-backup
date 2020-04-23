#!/bin/bash

if [ -z $NEO4J_ADDR ] ; then
    echo "You must specify a NEO4J_ADDR env var"
    exit 1
fi

if [ -z $S3_BUCKET_PATH ]; then
    echo "You must specify a BUCKET address such as gs://my-backups/"
    exit 1
fi

if [ -z $HEAP_SIZE ] ; then
    HEAP_SIZE=1G
fi

if [ -z $PAGE_CACHE ]; then
    PAGE_CACHE=1G
fi

if [ -z $BACKUP_NAME ]; then
    BACKUP_NAME=neo4j-backup
fi

BACKUP_SET="$BACKUP_NAME-$(date "+%Y-%m-%d")"

echo "=============== Neo4j Backup ==============================="
echo "Beginning backup from $NEO4J_ADDR to /data/$BACKUP_SET"
echo "Using heap size $HEAP_SIZE and page cache $PAGE_CACHE"
echo "To S3 bucket $S3_BUCKET_PATH"
echo "============================================================"

neo4j-admin backup \
    --from="$NEO4J_ADDR" \
    --backup-dir=/data \
    --name="$BACKUP_SET" \
    --pagecache=$PAGE_CACHE

echo "ls /data"
ls -al /data

if [ -d "/data/$BACKUP_SET" ] ; then
    echo "Backup size:"
    du -hs "/data/$BACKUP_SET"
else 
    echo "Backup file was not found. Terminating job."
    exit 1
fi

echo "Tarring -> /data/$BACKUP_SET.tar"
tar -cvf "/data/$BACKUP_SET.tar" "/data/$BACKUP_SET" --remove-files

echo "Zipping -> /data/$BACKUP_SET.tar.gz"
gzip -9 "/data/$BACKUP_SET.tar"

echo "Zipped backup size:"
du -hs "/data/$BACKUP_SET.tar.gz"

echo "Pushing /data/$BACKUP_SET.tar.gz -> $S3_BUCKET_PATH/$BACKUP_SET.tar.gz"
aws s3 cp "/data/$BACKUP_SET.tar.gz" "$S3_BUCKET_PATH/$BACKUP_SET.tar.gz"

exit $?