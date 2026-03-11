###############################################################
# certificate.tf — ACM SSL Certificate (manual DNS validation)
#
# After running terraform apply, go to:
#   AWS Console → Certificate Manager → your cert → Domains
# Copy the CNAME name + value and add them in GoDaddy DNS.
# Then run terraform apply again to complete.
###############################################################

resource "aws_acm_certificate" "main" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(local.common_tags, { Name = "${var.project_name}-cert" })
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn = aws_acm_certificate.main.arn
  timeouts {
    create = "10m"
  }
}
