# jenkins-on-ecs-fargate

A reference implementation of a secure, ephemeral Jenkins platform on AWS ECS Fargate, built with Terraform.

> **Status:** work in progress. Parts land through pull requests, one per component.

## What this will contain

- **Network:** VPC with public, private and isolated database subnets, NAT, VPC endpoints and flow logs.
- **Jenkins controller:** a single Fargate task with `JENKINS_HOME` on encrypted EFS, behind an HTTPS ALB, registered in Cloud Map.
- **Short-lived agents:** one Fargate agent template, task role and security group per environment (`dev`, `qa`, `uat`, `prod`).
- **Least-privilege IAM:** the controller can only launch agents. Each environment's agent reads only its own secrets and assumes only its own deploy role.
- **Access as code:** Okta OIDC SSO, role-based access in Git, a CI lockout guard and drift correction.
- **CI:** Terraform fmt/validate, tflint, checkov, hadolint, yamllint, pytest and gitleaks, with image builds pushed to ECR via GitHub OIDC.

The full README (architecture diagram, design decisions, deploy, verify, teardown and limits) arrives with the components.

## License

[MIT](LICENSE)
