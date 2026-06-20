output "web_custom_data" {
  description = "Base64 encoded setup script for the web tier (Nginx)"
  value       = filebase64("${path.module}/web_init.sh")
}

output "app_custom_data" {
  description = "Base64 encoded setup script for the app tier (Flask)"
  value       = filebase64("${path.module}/app_init.sh")
}