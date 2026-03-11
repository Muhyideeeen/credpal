###############################################################
# redis.tf — ElastiCache Redis (single node, Fargate-accessible)
###############################################################

###############################################################
# Security group — only allow Redis port from the app tasks
###############################################################

resource "aws_security_group" "redis" {
  name        = "${var.project_name}-redis-sg"
  description = "Allow Redis access from app tasks only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Redis from app containers"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-redis-sg" })
}

###############################################################
# Subnet group — ElastiCache must know which subnets to use
###############################################################

resource "aws_elasticache_subnet_group" "redis" {
  name       = "${var.project_name}-redis-subnet-group"
  subnet_ids = aws_subnet.private[*].id
  tags       = local.common_tags
}

###############################################################
# ElastiCache Redis cluster (single node — sufficient for this app)
###############################################################

# NOTE: ElastiCache does not support auth_token on aws_elasticache_cluster.
# Auth tokens (passwords) require the replication group resource instead.
resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis"
  description          = "Redis for ${var.project_name}"

  engine               = "redis"
  engine_version       = "7.0"
  node_type            = "cache.t3.micro"
  num_cache_clusters   = 1
  parameter_group_name = "default.redis7"
  port                 = 6379

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  # Password protection — requires transit_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = var.redis_password

  at_rest_encryption_enabled = true  # encrypt data on disk too

  tags = local.common_tags
}
