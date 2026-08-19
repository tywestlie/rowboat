resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${var.app_name}/rails_master_key"
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_string = var.rails_master_key
}

resource "aws_secretsmanager_secret" "anthropic_api_key" {
  name = "${var.app_name}/anthropic_api_key"
}

resource "aws_secretsmanager_secret_version" "anthropic_api_key" {
  secret_id     = aws_secretsmanager_secret.anthropic_api_key.id
  secret_string = var.anthropic_api_key
}

resource "aws_secretsmanager_secret" "ai_access_code" {
  name = "${var.app_name}/ai_access_code"
}

resource "aws_secretsmanager_secret_version" "ai_access_code" {
  secret_id     = aws_secretsmanager_secret.ai_access_code.id
  secret_string = var.ai_access_code
}
