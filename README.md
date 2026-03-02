# Flamingo Home Assignment - DevOps Engineer

This repository contains a Helm chart and local automation to deploy a FleetDM stack on Kubernetes.

## What is included

- Helm chart: `charts/fleetdm`
- Components deployed by the chart:
  - FleetDM server
  - MySQL
  - Redis
- Automated DB bootstrap on fresh install via `fleet prepare db` (initContainer)
- Automated MySQL user reconciliation before Fleet startup via initContainer
- Local cluster workflow with `kind`
- CI workflow to lint and release chart versions

## Prerequisites

- Docker
- `kind`
- `kubectl`
- `helm` (v3)

## Quick start

1. Create local cluster:

```bash
make cluster
```

2. Install chart:

```bash
make install
```

3. Open Fleet UI:

- `http://localhost:8080`

`kind-config.yaml` maps NodePort `30080` to host `8080`, so Fleet is reachable from the host and local agents.

## Teardown

Remove all deployed resources:

```bash
make uninstall
```

## Verification steps

1. Pods are running:

```bash
kubectl -n fleetdm get pods
```

Expected: Fleet, MySQL, and Redis pods should be `Running` and `Ready`.

2. Fleet health endpoint:

```bash
curl -fsS http://localhost:8080/api/latest/fleet/version
```

Expected: JSON response with Fleet version info.

3. MySQL readiness:

```bash
kubectl -n fleetdm exec deploy/fleetdm-mysql -- \
  mysqladmin ping -uroot -proot
```

Expected: `mysqld is alive`.

4. Redis readiness:

```bash
kubectl -n fleetdm exec deploy/fleetdm-redis -- redis-cli ping
```

Expected: `PONG`.

## Helm chart structure

- `charts/fleetdm/templates/fleet.yaml`: Fleet service and deployment
- `charts/fleetdm/templates/mysql.yaml`: MySQL service/deployment/PVC
- `charts/fleetdm/templates/redis.yaml`: Redis service/deployment/PVC
- `charts/fleetdm/templates/secret.yaml`: DB credentials secret

## CI chart release

GitHub Actions workflow: `.github/workflows/release-chart.yaml`

Pipeline behavior:

- Lints the chart (`helm lint`)
- Renders templates (`helm template`)
- Uses `helm/chart-releaser-action` to publish chart releases from `charts/`
