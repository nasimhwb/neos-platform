# PostgreSQL Service

This directory is reserved for custom PostgreSQL extensions and builds.

## Default Deployment
Currently, the service uses the official PostgreSQL Alpine image (`postgres:16.3-alpine`) configured in `compose/compose.database.yml`.

## Extending the Service
If you need to add custom PostgreSQL extensions (such as `PostGIS` or `pgvector` for AI services):
1. Create a `Dockerfile` in this directory.
2. Build it using `docker build -t custom-postgres .`.
3. Update `compose/compose.database.yml` to point to the local build context.
