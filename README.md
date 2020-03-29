# neo4j-backup
Docker container files that are used to backup Neo4j on EKS' Kubernetes

Needed environment variables:
- AWS_DEFAULT_REGION
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- NEO4J_ADDR
- S3_BUCKET_PATH
- HEAP_SIZE (optional) = 1G
- PAGE_CACHE (optional) = 1G
- BACKUP_NAME (optional) = neo4j-backup
