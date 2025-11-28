# Создание сети
resource "vkcs_networking_network" "db" {
  name           = "db-net"
  admin_state_up = true
}

# Создание подсети
resource "vkcs_networking_subnet" "db_subnetwork" {
  name            = "db-subnet"
  network_id      = vkcs_networking_network.db.id
  cidr            = "10.100.0.0/16"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Данные о внешней сети
data "vkcs_networking_network" "extnet" {
  name = "ext-net"
}

# Создание роутера
resource "vkcs_networking_router" "db_router" {
  name                = "db-router"
  admin_state_up      = true
  external_network_id = data.vkcs_networking_network.extnet.id
}

# Интерфейс роутера
resource "vkcs_networking_router_interface" "db" {
  router_id = vkcs_networking_router.db_router.id
  subnet_id = vkcs_networking_subnet.db_subnetwork.id
}

# Группа безопасности
resource "vkcs_networking_secgroup" "db_secgroup" {
  name        = "db-security-group"
  description = "Security group for database"
}

# Правило для доступа только с бэкенд-серверов (внутренний доступ)
resource "vkcs_networking_secgroup_rule" "mysql_backend_access" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = "10.0.0.0/16"  # Бэкенд-серверы
  security_group_id = vkcs_networking_secgroup.db_secgroup.id
  description       = "Allow MySQL access from backend servers"
}

# Правило для внешнего доступа (если нужно)
resource "vkcs_networking_secgroup_rule" "mysql_external_access" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 3306
  port_range_max    = 3306
  remote_ip_prefix  = "0.0.0.0/0"  # Или ограничьте конкретным IP
  security_group_id = vkcs_networking_secgroup.db_secgroup.id
  description       = "Allow MySQL external access"
}

# Правило для исходящего трафика
resource "vkcs_networking_secgroup_rule" "mysql_egress" {
  direction         = "egress"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = vkcs_networking_secgroup.db_secgroup.id
  description       = "Allow all outgoing traffic"
}

# Создание инстанса БД MySQL 8.0 с внешним IP
resource "vkcs_db_instance" "db_instance" {
  name              = "PanyutinMA_DB_mysql"
  availability_zone = "GZ1"
  
  datastore {
    type    = "mysql"
    version = "8.0"
  }
  
  flavor_id = "2df6e3ec-5939-4d28-a818-89558ff1b7ab"  # STD2-2-8
  
  # ВКЛЮЧАЕМ внешний IP
  floating_ip_enabled = true
  
  network {
    uuid            = vkcs_networking_network.db.id
    security_groups = [vkcs_networking_secgroup.db_secgroup.id]
  }
  
  size        = 20
  volume_type = "ceph-ssd"
  
  disk_autoexpand {
    autoexpand    = true
    max_disk_size = 1000
  }

  depends_on = [
    vkcs_networking_router_interface.db,
  ]
}

# Создание базы данных
resource "vkcs_db_database" "db_database" {
  name    = var.database_name
  dbms_id = vkcs_db_instance.db_instance.id
}

# Создание пользователя БД
resource "vkcs_db_user" "db_user" {
  name      = var.database_user
  password  = var.db_user_password
  dbms_id   = vkcs_db_instance.db_instance.id
  databases = [vkcs_db_database.db_database.name]
}

# Output values
output "mysql_host_internal" {
  description = "MySQL internal IP address"
  value       = length(vkcs_db_instance.db_instance.ip) > 0 ? vkcs_db_instance.db_instance.ip[0] : "Not available"
}

output "mysql_host_external" {
  description = "MySQL external (floating) IP address"
  value       = vkcs_db_instance.db_instance.floating_ip_enabled ? "External IP enabled - check in VK Cloud console" : "External IP disabled"
}

output "database_name" {
  description = "Database name"
  value       = var.database_name
}

output "database_user" {
  description = "Database username"
  value       = var.database_user
}

output "mysql_instance_id" {
  description = "MySQL instance ID"
  value       = vkcs_db_instance.db_instance.id
}

output "connection_string" {
  description = "MySQL connection string"
  value       = "mysql://${var.database_user}:${var.db_user_password}@${length(vkcs_db_instance.db_instance.ip) > 0 ? vkcs_db_instance.db_instance.ip[0] : "host_not_available"}/${var.database_name}"
  sensitive   = true
}

output "security_group_id" {
  description = "Security group ID"
  value       = vkcs_networking_secgroup.db_secgroup.id
}
