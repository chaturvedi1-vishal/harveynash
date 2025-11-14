# Section 1(c) – IRSA for order-processor

- ServiceAccount: orders/order-processor
- IAM Role: orders-reader-irsa
- Permissions: s3:ListBucket and s3:GetObject on s3://incoming-orders
- Mechanism: IAM Role for Service Accounts (IRSA)
- Validation: pod using SA successfully lists objects in incoming-orders
