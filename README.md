# loghouse

Log platform on ClickHouse, OpenTelemetry and HyperDX. Runs locally with Docker Compose and on GKE with two replicas, three Keepers and a GCS cold tier.

Write-up: https://anuragojha.dev/blogs/building-a-log-platform-on-clickhouse-and-gke

## Layout

- `generator/` log generator, `INCIDENT=<service>` breaks one service
- `sql/`, `otel/`, `docker-compose.yml` local stack
- `infra/` Terraform for GKE, Artifact Registry, GCS, Secret Manager
- `k8s/` Keeper, ClickHouse, schema, OTel, HyperDX on GKE
- `lab/` 10M-row ORDER BY experiment

## Local

```bash
docker compose up -d
```

HyperDX: http://localhost:8080

## GKE

```bash
cd infra && terraform apply
kubectl apply -f k8s/secrets.yaml -f k8s/keeper.yaml -f k8s/clickhouse.yaml
# then k8s/schema.sql, then the remaining k8s/*.yaml
```

Requires the Altinity operator and External Secrets installed with Helm. Replace the project ID `loghouse-318a33` with yours.
