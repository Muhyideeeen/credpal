# CredApp — Production-Ready Node.js DevOps Pipeline

A production-grade Node.js REST API with full CI/CD automation, containerisation, and cloud infrastructure on AWS.

---

## Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/health` | Returns service health status |
| GET | `/status` | Returns app and Redis connection status |
| POST | `/process` | Processes a submitted payload |

---

## Part 1 — Running the Application Locally

### Prerequisites
- Docker and Docker Compose installed
- Node.js 20+ (for running without Docker)

### With Docker Compose (recommended)

```bash
# Clone the repository
git clone https://github.com/muhyideen/credapp.git
cd credapp

# Copy environment file
cp .env.example .env

# Start the app and Redis
docker compose up --build
```

The app will be available at: `http://localhost:3000`

### Without Docker

```bash
cd app
npm install
npm start
```

> Requires a local Redis instance running on port 6379.

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `APP_PORT` | Port the app listens on | `3000` |
| `REDIS_HOST` | Redis hostname | `redis` |
| `REDIS_PORT` | Redis port | `6379` |
| `REDIS_PASSWORD` | Redis password (optional) | - |
| `NODE_ENV` | Environment | `development` |

### Running Tests

```bash
cd app
npm test
```

---

## Part 2 — Accessing the Application

### Locally
```
http://localhost:3000/health
http://localhost:3000/status
```

### Production
```
https://www.yourdomain.com/health
https://www.yourdomain.com/status
```

Traffic flows:
```
Internet → ALB (HTTPS:443) → ECS Fargate Tasks (HTTP:3000) → ElastiCache Redis
```

---

## Part 3 — Deploying the Application

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.5.0 installed
- A domain name with DNS access

### Steps

**1. Configure Terraform variables**
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:
```hcl
project_name    = "credapp"
environment     = "production"
aws_region      = "us-east-1"
domain_name     = "yourdomain.com"
container_image = "muhyideen/credapp:latest"
```

**2. Provision infrastructure**
```bash
terraform init
terraform apply
```

**3. Add DNS records**

After the first apply, go to AWS Console → Certificate Manager → your certificate and copy the CNAME validation records. Add them to your DNS provider, then run:
```bash
terraform apply
```

**4. Push your image**

The GitHub Actions pipeline handles this automatically on every push to `main`. To trigger a deployment manually:
```bash
git push origin main
```

**5. Monitor the deployment**

```bash
# View live container logs
aws logs tail /ecs/credapp --follow

# Check ECS service status
aws ecs describe-services \
  --cluster credapp-cluster \
  --services credapp-service
```

### CI/CD Pipeline

The GitHub Actions pipeline runs automatically on every push or pull request to `main`:

```
push to main
      │
      ▼
  [Test]  ← install deps, run tests (runs on PRs too)
      │
      ▼
  [Build & Push]  ← builds Docker image, pushes to DockerHub as muhyideen/credapp
      │
      ▼
  [Deploy]  ← updates ECS task definition, triggers rolling deployment
```

---

## Key Decisions

### Security

**No secrets in source code.** All sensitive values are handled through:
- GitHub Actions Secrets (encrypted) for CI/CD credentials — `DOCKERHUB_TOKEN`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `.env` is git-ignored and never committed

**Non-root container.** The app runs as `USER node` (UID 1000) inside the container, following the principle of least privilege. This is enforced both in the Dockerfile and in the ECS task definition.

**Private networking.** ECS Fargate tasks and ElastiCache Redis run in private subnets with no public IP. Only the Application Load Balancer is internet-facing. The Redis instance has no password configured because it is only reachable from within the VPC by the app security group — the VPC is the security boundary.

**HTTPS enforced.** The ALB listener on port 80 issues a permanent 301 redirect to HTTPS. SSL is terminated at the ALB using an AWS-managed ACM certificate that auto-renews.

### CI/CD

**GitHub Actions** was chosen for its native integration with the GitHub repository, eliminating the need for a separate CI server. The pipeline separates concerns into three jobs — test, build, and deploy — so a failing test never produces or ships an image.

**DockerHub** is used as the public image registry since the assignment specifies a public repository. The image is tagged with both the short git SHA (for traceability) and `latest` (for convenience).

**Docker layer caching** (`cache-from: type=gha`) is enabled to speed up repeat builds by reusing unchanged layers between pipeline runs.

### Infrastructure

**ECS Fargate** was chosen over EC2 because the application is already containerised, making Fargate the natural deployment target. It eliminates the need to manage, patch, or scale servers, and natively supports the zero-downtime rolling deployment strategy required by the assignment.

**Rolling deployment** was chosen over blue-green because it is simpler to operate for a single-service app and is natively supported by ECS. With `minimum_healthy_percent = 50` and `maximum_percent = 200`, ECS always keeps at least one task running while new tasks start. The deployment circuit breaker automatically rolls back if new tasks fail health checks.

**ElastiCache Redis** is used instead of a sidecar Redis container because a containerised Redis would lose all data on every deployment. ElastiCache is a managed, persistent service that survives task restarts and redeployments.

**Two availability zones** are used for both the ALB subnets and Fargate tasks, providing fault tolerance if one AWS data centre becomes unavailable.

### Observability

Container logs are streamed to **AWS CloudWatch Logs** under `/ecs/credapp` with a 30-day retention policy. The ALB health check polls `/health` every 30 seconds and removes unhealthy tasks from the target group automatically.
