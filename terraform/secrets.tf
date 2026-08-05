resource "aws_secretsmanager_secret" "rails_master_key" {
  name = "${var.app_name}/rails_master_key"
}

resource "aws_secretsmanager_secret_version" "rails_master_key" {
  secret_id     = aws_secretsmanager_secret.rails_master_key.id
  secret_string = var.rails_master_key
}