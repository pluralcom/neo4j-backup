# plural-neo4j-backup
🐳 Docker container files that are used to backup Neo4j on EKS' Kubernetes

Environment variables:
- AWS_DEFAULT_REGION
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- S3_BUCKET_PATH
- NEO4J_ADDR
- HEAP_SIZE (optional) = 1G
- PAGE_CACHE (optional) = 1G
- BACKUP_NAME (optional) = neo4j-backup

[Plural](https://plural.com) ❤️ Open source