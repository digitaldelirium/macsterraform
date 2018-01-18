data "terraform_remote_state" "state" {
  backend = "azurerm"

  config {
    storage_account_name = "macsstatestorage"
    container_name       = "tfstate"
    key                  = "prod.state.tfstate"
    access_key           = "${var.access_key}"
  }
}

data "terraform_remote_state" "service" {
  backend = "azurerm"

  config {
    storage_account_name = "macsstatestorage"
    container_name       = "tfstate"
    key                  = "prod.state.tfstate"
    access_key           = "${var.access_key}"
  }
}

terraform {
  backend "azurerm" {
    storage_account_name = "macsstatestorage"
    container_name       = "tfstate"
    key                  = "prod.docker.tfstate"
  }
}

provider "docker" {
  host      = "tcp://${var.public_ip}:2376"
  cert_path = "/home/ian/.docker"

  registry_auth {
    address = "registry.hub.docker.com"
    username = "macscampingarea"
    password = "${var.docker_password}"
  }
}

data "docker_registry_image" "mariadb" {
  name = "mariadb:latest"
}

data "docker_registry_image" "portainer" {
  name = "portainer/portainer:latest"
}

data "docker_registry_image" "phpmyadmin" {
  name = "phpmyadmin/phpmyadmin:latest"
}

data "docker_registry_image" "aspnetcore" {
  name = "microsoft/aspnetcore:2"
}

data "docker_registry_image" "aspnetcore-build" {
   name = "microsoft/aspnetcore-build:2"
}

resource "docker_volume" "sql_data" {
  name = "mysql_data"
}

resource "docker_volume" "sql_logs" {
  name = "mysql_logs"
}

resource "docker_volume" "portainer_data" {
  name = "portainer_data"
}

resource "docker_volume" "nginx_logs" {
  name = "nginx_log"
}

resource "docker_image" "portainer" {
  name          = "${data.docker_registry_image.portainer.name}"
  pull_triggers = ["${data.docker_registry_image.portainer.sha256_digest}"]
}

resource "docker_image" "mariadb" {
  name          = "${data.docker_registry_image.mariadb.name}"
  pull_triggers = ["${data.docker_registry_image.mariadb.sha256_digest}"]
}

resource "docker_image" "phpmyadmin" {
  name          = "${data.docker_registry_image.phpmyadmin.name}"
  pull_triggers = ["${data.docker_registry_image.phpmyadmin.sha256_digest}"]
}

resource "docker_image" "aspnetcore" {
  name          = "${data.docker_registry_image.aspnetcore.name}"
  pull_triggers = ["${data.docker_registry_image.aspnetcore.sha256_digest}"]
}

resource "docker_image" "aspnetcore-build" {
  name = "${data.docker_registry_image.aspnetcore-build.name}"
  pull_triggers = ["${data.docker_registry_image.aspnetcore-build.sha256_digest}"]
}

resource "docker_container" "portainer" {
  name     = "portainer"
  image    = "${docker_image.portainer.latest}"
  restart  = "always"
  must_run = true
  hostname = "admin.macscampingarea.com"

  volumes {
    volume_name    = "${docker_volume.portainer_data.name}"
    container_path = "/data"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  ports {
    internal = 9000
    external = 9000
  }
}

resource "docker_container" "mariadb" {
  name = "mariadb"
  image = "${docker_image.mariadb.latest}"
  restart = "always"
  must_run = "true"
  depends_on = ["random_string.mysql_password"]
  hostname  = "mariadb.macscampingarea.com"

  volumes {
    volume_name = "${docker_volume.sql_data.name}"
    container_path = "/var/lib/mysql"
  }

  ports {
    internal = 3306
    external = 3306
  }

  env = [
    "MYSQL_ROOT_PASSWORD=${random_string.mysql_password.result}",
    "MYSQL_USER=macs",
    "MYSQL_PASSWORD=${random_string.macs_password.result}"
  ]
}

resource "docker_container" "phpmyadmin" {
  name = "phpmyadmin"
  image = "${docker_image.phpmyadmin.latest}"
  restart = "always"
  must_run = "true"
  depends_on = ["docker_container.mariadb"]
  links = ["mariadb:db"]
  hostname = "mysqladmin.macscampingarea.com"

  ports {
    internal = 80
    external = 8080
  }
}

resource "random_string" "mysql_password" {
  length = 24
  special = false
}

resource "random_string" "macs_password" {
  length = 16
  special = false
}

/*
resource "azurerm_key_vault_secret" "mysql_password" {
  name = "mysql-root-password"
  value = "${random_string.mysql_password.result}"
  vault_uri = "${var.macs_vault}"
}

resource "azurerm_key_vault_secret" "macs_password" {
  name = "macs-password"
  value = "${random_string.macs_password.result}"
  vault_uri = "${var.macs_vault}"
}
*/