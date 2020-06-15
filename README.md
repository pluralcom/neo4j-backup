# plural-neo4j-backup
🐳 Docker container files that are used to backup Neo4j on EKS' Kubernetes

![Release and deploy to docker hub](https://github.com/pluralcom/neo4j-backup/workflows/Release%20and%20deploy%20to%20docker%20hub/badge.svg)

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
