# Section 1(b) – OpsUser

- IAM Role `OpsUser` can be assumed only by user arn:aws:iam::1234566789001:user/ops-alice
- Access restricted to IP 52.94.236.248
- Mapped to Kubernetes user `ops-viewer`
- Bound to built-in ClusterRole `view` in `ops` namespace
- Provides read-only access to resources (pods, services, configmaps, etc.) in that namespace
