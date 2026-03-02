# Architectural Design Document — Company Inc. (AWS)

## 1. Executive Summary
Company Inc. should deploy on **AWS** using **EKS** for compute and a managed MongoDB platform (**MongoDB Atlas on AWS**) for data. The design prioritizes: security for sensitive data, low initial cost, clean scaling to millions of users, and fast CI/CD delivery.

Core principles:
- Strong environment isolation (separate AWS accounts).
- Private-by-default networking.
- Managed services to reduce ops burden.
- GitOps-style Kubernetes delivery with automated rollback capability.
- Infrastructure as Code for reproducible and auditable platform changes.

---

## 2. Cloud Environment Structure

### Recommended AWS account model (4 accounts)
1. **Management/Security account**
- AWS Organizations, IAM Identity Center (SSO), CloudTrail org logs, GuardDuty/Security Hub aggregation, central KMS policies.

2. **Shared Services account**
- CI runners (if self-hosted), artifact/cache services, cross-account ECR replication, centralized observability tooling.

3. **Non-Production account**
- Dev + staging EKS clusters (or namespaces split by environment), integration tests, pre-prod validation.

4. **Production account**
- Production EKS and production data planes only.

### Why AWS
- Mature EKS ecosystem and autoscaling integrations.
- Strong identity/security primitives (Organizations, SCP, IAM, KMS, WAF, Shield).
- Broad regional/AZ coverage and managed services that fit startup growth.

### Why this structure
- Blast-radius reduction and safer access control.
- Clear billing per environment/account.
- Easier audit/compliance path for sensitive data.

---

## 3. Network Design

### VPC design (per account/environment)
- One VPC per environment (at minimum prod and non-prod).
- **3 AZs** for HA.
- Subnet layout per AZ:
  - **Public subnet**: ALB/NAT only.
  - **Private app subnet**: EKS worker nodes/pods.
  - **Private data subnet**: endpoints/data connectivity components.

### Ingress and egress
- Internet traffic -> **CloudFront** -> **WAF** -> **ALB Ingress Controller** -> EKS services.
- SPA static assets served via S3 + CloudFront.
- API ingress only through ALB/WAF; no public node exposure.
- Restrict outbound internet with NAT + egress policies + VPC endpoints (ECR, S3, CloudWatch, STS, Secrets Manager).

### Security controls
- Security Groups least-privilege between ALB, nodes, and external services.
- Kubernetes NetworkPolicies for pod-level east-west restrictions.
- Private EKS API endpoint (or restricted CIDR access).
- End-to-end TLS (ACM at edge; optional service mesh mTLS internally).
- Secrets in AWS Secrets Manager + KMS encryption.
- Enable VPC Flow Logs, CloudTrail, GuardDuty, Security Hub.

---

## 4. Compute Platform (EKS)

### Cluster model
- Separate EKS clusters for non-prod and prod.
- Use **managed node groups** plus **Cluster Autoscaler** (or Karpenter).
- Baseline node groups:
  - `system` group: critical cluster components.
  - `app-general` group: Flask API workloads.
  - optional `spot` group for non-critical/background workloads.

### Scaling and resources
- **HPA** on API deployment (CPU/memory + custom RPS metrics).
- **VPA** in recommendation mode first; apply to stable workloads later.
- Pod requests/limits mandatory; namespace ResourceQuotas and LimitRanges.
- PodDisruptionBudgets for API components.

### Containerization strategy
- Multi-stage Docker builds (small runtime images, non-root user, pinned dependencies).
- Image scanning in CI (Trivy/Grype) + dependency scanning (SCA).
- Registry: **Amazon ECR** per environment/account with lifecycle policies and immutable tags.

### CI/CD
- CI (GitHub Actions/GitLab CI): test, lint, SAST/SCA, image build, sign, push to ECR.
- CD: ArgoCD-based GitOps deployment of Helm charts to EKS.
- Environment promotion model: dev -> staging -> prod with approvals and automated rollback.

### GitOps with ArgoCD
- Deploy ArgoCD in each cluster (or centralized with strict RBAC and project boundaries).
- Source of truth: Git repository with Helm values per environment.
- ArgoCD continuously reconciles desired state -> cluster state, detects drift, and supports rollback by Git revert.
- Promotion flow:
  - CI updates image tag in environment manifest (PR-based).
  - Merge to `main` (or env branch) triggers ArgoCD sync.
  - Prod sync can be manual approval gate.

---

## 5. Database (MongoDB)

### Recommended service
- **MongoDB Atlas (AWS)** with PrivateLink peering to VPC.

### Why Atlas
- Native MongoDB operational model without self-managing replica sets/sharding.
- Strong backup/restore automation, monitoring, and security controls.
- Scales from startup workloads to high-throughput clusters.

### Availability and DR
- Production: **multi-AZ replica set** (minimum 3 nodes across AZs).
- Backups: continuous backup/PITR + daily snapshots; separate retention for non-prod/prod.
- Disaster recovery:
  - Same-region HA by default.
  - Optional cross-region read replica and tested failover runbook.
  - Quarterly DR drills with RTO/RPO targets (example: RTO < 1h, RPO < 15 min).

### Security for sensitive data
- Encryption at rest (KMS-backed) and in transit (TLS 1.2+).
- DB users with least privilege; short-lived credentials from secret manager.
- Audit logs exported to central log account/SIEM.

---

## 6. Operational Best Practices
- Terraform for all cloud resources and base cluster add-ons (VPC, EKS, IAM, ECR, CloudFront/WAF, monitoring primitives).
- Terraform state in S3 with DynamoDB locking; separate state/workspaces per account/environment.
- Reusable Terraform modules for networking, EKS, IAM, and observability to standardize environments.
- Observability: CloudWatch + Prometheus/Grafana + centralized logs.
- SLOs and alerting for API latency/error rate, pod health, DB saturation.
- Policy as code: OPA/Kyverno (block privileged pods, require limits, signed images).
- Cost controls: autoscaling, right-sizing, spot for non-critical, ECR/S3 lifecycle policies.

This architecture is intentionally minimal for early stage operation and can scale linearly by adding nodes, replicas, and Atlas tier capacity without re-platforming.
