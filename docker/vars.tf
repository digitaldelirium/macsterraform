variable "access_key" {
  description = "access key to write to storage account"
}

variable "docker_password" {
  description = "Docker Hub Registry Password"
}

variable "public_ip" {
  description = "Public IP of Docker Server"
  default = "40.71.181.141"
}

variable "macs_vault" {
  description = "Macs camping vault URI"
  default = "https://macscampvault.vault.azure.net"
}

variable "mysql_root_password" {
  description = "MariaDB/MySQL root password"
}

variable "macs_password" {
  description = "Mac's database user password"
}