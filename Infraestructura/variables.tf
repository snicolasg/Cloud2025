variable "region" {
  description = "The AWS region to deploy in"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_1_cidr" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_subnet_1_cidr" {
  description = "CIDR block for the first private subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2_cidr" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "az_1" {
  description = "Availability zone for the first public subnet"
  type        = string
  default     = "us-east-1a"
}

variable "az_2" {
  description = "Availability zone for the second public subnet"
  type        = string
  default     = "us-east-1b"
}

variable "az_3" {
  description = "Availability zone for the first private subnet"
  type        = string
  default     = "us-east-1c"
}

variable "az_4" {
  description = "Availability zone for the second private subnet"
  type        = string
  default     = "us-east-1d"
}

variable "ssh_key_name" {
 description = "Nombre de la key pair existente en AWS para acceso SSH"
 type        = string
 default     = "vockey"
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "eks-cluster-Obligatorio2025"
}

variable "node_group_name" {
  description = "Name of the EKS node group"
  type        = string
  default     = "node-group-Obligatorio2025"
}

variable "desired_capacity" {
  description = "Desired number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of nodes in the EKS node group"
  type        = number
  default     = 10
}

variable "min_capacity" {
  description = "Minimum number of nodes in the EKS node group"
  type        = number
  default     = 2
}

variable "db_username" {
  description = "Usuario de la base de datos RDS"
  type        = string
  default     = "db_user"
  sensitive   = true
}

variable "db_password" {
  description = "Contraseña de la base de datos RDS"
  type        = string
  default     = "db_password"
  sensitive   = true
}
