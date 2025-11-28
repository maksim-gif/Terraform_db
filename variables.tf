variable "username" {
  description = "VK Cloud username email"
  type        = string
}

variable "password" {
  description = "VK Cloud password"
  type        = string
  sensitive   = true
}

variable "project_id" {
  description = "VK Cloud project ID"
  type        = string
}

variable "db_user_password" {
  description = "Database user password"
  type        = string
  sensitive   = true
  default     = "7h78gs.p70aG85wU0"  # Новый пароль
}

variable "database_name" {
  description = "Database name"
  type        = string
  default     = "app_database"
}

variable "database_user" {
  description = "Database username"
  type        = string
  default     = "app_user"
}

variable "db_instance_flavor" {
  type    = string
  default = "STD2-2-8"
}

variable "region" {
  description = "VK Cloud region"
  type        = string
  default     = "RegionOne"
}

variable "vkcs_auth_url" {
  description = "VK Cloud authentication URL"
  type        = string
  default     = "https://infra.mail.ru:35357/v3/"
}
