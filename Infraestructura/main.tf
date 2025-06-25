#Define el proveedor AWS para el proyecto Terraform
provider "aws" {
  region = var.region
}

#Busca un rol IAM existente llamado LabRole
data "aws_iam_role" "labrole" {
  name = "LabRole"
}

#Crea una VPC con el bloque CIDR definido en la variable var.vpc_cidr
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
}

#Crea dos subredes públicas en diferentes zonas de disponibilidad (var.az_1 y var.az_2)
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = var.az_1
  map_public_ip_on_launch = true
}

#Crea dos subredes privadas para usos internos, en diferentes zonas (var.az_3 y var.az_4)
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.az_2
  map_public_ip_on_launch = true
}

#Crea un gateway de internet para permitir tráfico entrante/saliente en las subredes públicas
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.az_3
}

#Configura una tabla de rutas para permitir acceso a internet mediante el gateway.
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.az_4
}

#Asocia la tabla de rutas pública a las subredes públicas.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

#Crea un clúster EKS utilizando subredes públicas y privadas. Asocia el rol IAM LabRole al clúster.
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

#Crea un grupo de nodos para el clúster EKS en las subredes públicas. Configura escalado automático. Permite acceso remoto usando la clave SSH especificada.
resource "aws_route_table_association" "public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public.id
}

#Asocia la tabla de rutas pública a las subredes públicas.
resource "aws_route_table_association" "public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public.id
}

#Crea un clúster EKS utilizando subredes públicas y privadas.
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = data.aws_iam_role.labrole.arn

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id, aws_subnet.private_subnet_1.id, aws_subnet.private_subnet_2.id]
  }
}

#Crea un grupo de nodos para el clúster EKS en las subredes públicas.
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.labrole.arn
  subnet_ids      = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
 
  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  remote_access {
    ec2_ssh_key = var.ssh_key_name
  }
}

#Crea un grupo de seguridad para permitir acceso SSH a los nodos del clúster.
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks_nodes_sg"
  description = "Permitir SSH a los nodos EKS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Define un grupo de subredes privadas que RDS utilizará.
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = [
    aws_subnet.private_subnet_1.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "RDS subnet group"
  }
}

#Permite acceso al puerto 3306 (MySQL) desde la VPC para EKS.
resource "aws_security_group" "rds_sg" {
  name        = "rds_sg"
  description = "Permitir acceso a RDS desde EKS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Crea una instancia RDS MySQL privada con replicación multi-AZ.
resource "aws_db_instance" "primary" {
  identifier             = "mi-db-principal"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "database_name"
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = true
  publicly_accessible    = false
  multi_az               = true
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
}

#Define un almacén para guardar backups.
resource "aws_backup_vault" "rds_backup_vault" {
  name        = "rds-backup-vault"
  tags = {
    Name = "RDS Backup Vault"
  }
}

#Programa backups diarios de la base de datos.
resource "aws_backup_plan" "rds_backup_plan" {
  name = "rds-backup-plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.rds_backup_vault.name
    schedule          = "cron(0 5 * * ? *)" # Todos los días a las 5 AM UTC
    start_window      = 60
    completion_window = 180
    lifecycle {
      delete_after = 30 # Días antes de eliminar el backup
    }
  }
}

#Aplica el plan de backup al RDS creado.
resource "aws_backup_selection" "rds_backup_selection" {
  iam_role_arn = data.aws_iam_role.labrole.arn
  name         = "rds-backup-selection"
  plan_id      = aws_backup_plan.rds_backup_plan.id

  resources = [
    aws_db_instance.primary.arn
  ]
}