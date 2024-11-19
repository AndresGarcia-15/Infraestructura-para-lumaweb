variable "name_prefix" {
  default     = "postgresqlfs"
  description = "Prefix of the resource name."
}

variable "location" {
  default     = "Canada Central"
  description = "Location of the resource."
}

variable "db_server_name" {
  default     = "postgresqlfs-akita-server"
  description = "Nombre del servidor de PostgreSQL."
}

variable "db_name" {
  default     = "postgresqlfs-akita-db"
  description = "Nombre de la base de datos de PostgreSQL."
}

variable "admin_password" {
  default     = "Z@QttY5oy8!AN$bg###w"
  description = "Contraseña del administrador de PostgreSQL."
}

variable "git_token" {
  description = "The GitHub token"
  type        = string
}