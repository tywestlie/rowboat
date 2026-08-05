resource "aws_acm_certificate" "app" {
  domain_name       = "rowboat.westlie.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.app_name}-cert"
  }
}

output "acm_validation_records" {
  description = "DNS records to add in Cloudflare for certificate validation"
  value = [
    for dvo in aws_acm_certificate.app.domain_validation_options : {
      name  = dvo.resource_record_name
      type  = dvo.resource_record_type
      value = dvo.resource_record_value
    }
  ]
}