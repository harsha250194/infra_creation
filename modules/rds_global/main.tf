########################################################################################################################
# Name: rds-global-cluster.tf
# Purpose: Create a Aurora Global Cluster 
# Version: 1.0
# Copyright: BeyondSoft Consulting, Inc
########################################################################################################################

# Aurora Global Cluster
resource "aws_rds_global_cluster" "global_cluster" {
  provider                  = aws.main
  global_cluster_identifier = "${var.global_prefix}-global-rds"
  source_db_cluster_identifier = aws_rds_cluster.primary_cluster.arn
  force_destroy = true
  # database_name             = var.db_name
  # engine                    = var.db_engine
  # engine_version            = var.db_engine_version
  # storage_encrypted         = var.storage_encrypted

  lifecycle {
    ignore_changes = [engine_version]
  }
}

resource "aws_db_subnet_group" "primary_db_subnet_group" {
  provider   = aws.main
  name       = "${var.global_prefix}-${var.aws_primary_region}-subnet-group"
  subnet_ids = var.primary_subnet_ids
}

resource "aws_db_subnet_group" "secondary_db_subnet_group" {
  provider   = aws.second
  name       = "${var.global_prefix}-${var.aws_secondary_region}-subnet-group"
  subnet_ids = var.secondary_subnet_ids

  # The first cluster to spin up takes the primary role automatically, so we force the secondary cluster creation to wait until the primary cluster is spun up
  depends_on = [aws_rds_cluster.primary_cluster]
}

resource "aws_security_group" "primary" {
  provider = aws.main
  name     = "${var.global_prefix}-${var.aws_primary_region}-sg"
  vpc_id   = var.primary_vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = concat(var.primary_vpc_cidr, var.secondary_vpc_cidr)
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "secondary" {
  provider = aws.second
  name     = "${var.global_prefix}-${var.aws_secondary_region}-sg"
  vpc_id   = var.secondary_vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = concat(var.primary_vpc_cidr, var.secondary_vpc_cidr)
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_rds_cluster" "primary_cluster" {
  provider               = aws.main
  database_name          = var.db_name
  master_username        = var.master_username
  master_password        = var.master_password
  vpc_security_group_ids = [aws_security_group.primary.id]
  db_subnet_group_name   = aws_db_subnet_group.primary_db_subnet_group.id
  # db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.primary_cluster_pg.id
  engine                    = var.db_engine
  engine_mode               = var.db_engine_mode
  engine_version            = var.db_engine_version
  storage_encrypted         = var.storage_encrypted
  kms_key_id                = var.primary_rds_kms_key
  # global_cluster_identifier = aws_rds_global_cluster.global_cluster.id
  snapshot_identifier = var.snapshot_identifier
  cluster_identifier        = "${var.global_prefix}-${var.aws_primary_region}-db-cluster"
  final_snapshot_identifier = "${var.global_prefix}-${var.aws_primary_region}-db-cluster"
  skip_final_snapshot       = var.skip_final_snapshot
  backup_retention_period   = var.backup_retention_period

  lifecycle {
    ignore_changes = [engine_version, master_username, master_password, global_cluster_identifier]
  }

  tags = var.tags
}

resource "aws_rds_cluster" "secondary_cluster" {
  provider               = aws.second
  vpc_security_group_ids = [aws_security_group.secondary.id]
  db_subnet_group_name   = aws_db_subnet_group.secondary_db_subnet_group.id
  # db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.secondary_cluster_pg.id
  engine                    = var.db_engine
  engine_mode               = var.db_engine_mode
  storage_encrypted         = var.storage_encrypted
  kms_key_id                = var.secondary_rds_kms_key
  source_region             = var.aws_primary_region # Required for cross region read replication of an encrypted cluster
  engine_version            = var.db_engine_version
  global_cluster_identifier = aws_rds_global_cluster.global_cluster.id
  cluster_identifier        = "${var.global_prefix}-${var.aws_secondary_region}-db-cluster"
  final_snapshot_identifier = "${var.global_prefix}-${var.aws_secondary_region}-db-cluster"
  skip_final_snapshot       = var.skip_final_snapshot

  lifecycle {
    ignore_changes = [engine_version, global_cluster_identifier, replication_source_identifier]
  }

  depends_on = [aws_rds_cluster.primary_cluster]
  tags = var.tags
}

resource "aws_rds_cluster_instance" "primary_cluster_instances" {
  provider             = aws.main
  count                = var.primary_cluster_instance_count
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.cluster_instance_class
  db_subnet_group_name = aws_db_subnet_group.primary_db_subnet_group.id
  # db_parameter_group_name = aws_db_parameter_group.primary_db_pg.id
  cluster_identifier = aws_rds_cluster.primary_cluster.id
  identifier         = "${var.global_prefix}-${var.aws_primary_region}-db-instance-${count.index}"

  lifecycle {
    ignore_changes = [engine_version]
  }

  tags = var.tags
}

resource "aws_rds_cluster_instance" "secondary_cluster_instances" {
  provider             = aws.second
  count                = var.secondary_cluster_instance_count
  engine               = var.db_engine
  engine_version       = var.db_engine_version
  instance_class       = var.cluster_instance_class
  db_subnet_group_name = aws_db_subnet_group.secondary_db_subnet_group.id
  # db_parameter_group_name = aws_db_parameter_group.secondary_db_pg.id
  cluster_identifier = aws_rds_cluster.secondary_cluster.id
  identifier         = "${var.global_prefix}-${var.aws_secondary_region}-db-instance-${count.index}"

  lifecycle {
    ignore_changes = [engine_version]
  }

  tags = var.tags
}

################################################################################
# Upload primary and secondary outputs to SSM parameter in both regions
################################################################################

# Primary
resource "aws_ssm_parameter" "main_primary_endpoint" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/primary-endpoint"
  description = "RDS primary cluster (${var.aws_primary_region}) endpoint for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.primary_cluster.endpoint
}

resource "aws_ssm_parameter" "main_secondary_endpoint" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/secondary-endpoint"
  description = "RDS secondary cluster (${var.aws_secondary_region}) endpoint for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.secondary_cluster.endpoint
}

resource "aws_ssm_parameter" "main_primary_port" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/primary-port"
  description = "RDS primary cluster (${var.aws_primary_region}) port for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.primary_cluster.port
}

resource "aws_ssm_parameter" "main_secondary_port" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/secondary-port"
  description = "RDS secondary cluster (${var.aws_secondary_region}) port for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.secondary_cluster.port
}

resource "aws_ssm_parameter" "main_primary_username" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/primary-username"
  description = "RDS primary cluster (${var.aws_primary_region}) master username for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.primary_cluster.master_username
}

resource "aws_ssm_parameter" "main_secondary_username" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/secondary-username"
  description = "RDS secondary cluster (${var.aws_secondary_region}) master username for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.secondary_cluster.master_username
}

resource "aws_ssm_parameter" "main_primary_password" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/primary-password"
  description = "RDS primary cluster (${var.aws_primary_region}) password for ${var.global_prefix}"
  type = "SecureString"
  value = var.master_password
}

resource "aws_ssm_parameter" "main_secondary_password" {
  provider = aws.main
  name = "/${var.global_prefix}/rds-global/secondary-password"
  description = "RDS secondary cluster (${var.aws_secondary_region}) password for ${var.global_prefix}"
  type = "SecureString"
  value = var.master_password
}

# Secondary
resource "aws_ssm_parameter" "second_primary_endpoint" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/primary-endpoint"
  description = "RDS primary cluster (${var.aws_primary_region}) endpoint for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.primary_cluster.endpoint
}

resource "aws_ssm_parameter" "second_secondary_endpoint" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/secondary-endpoint"
  description = "RDS secondary cluster (${var.aws_secondary_region}) endpoint for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.secondary_cluster.endpoint
}

resource "aws_ssm_parameter" "second_primary_port" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/primary-port"
  description = "RDS primary cluster (${var.aws_primary_region}) port for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.primary_cluster.port
}

resource "aws_ssm_parameter" "second_secondary_port" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/secondary-port"
  description = "RDS secondary cluster (${var.aws_secondary_region}) port for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.secondary_cluster.port
}

resource "aws_ssm_parameter" "second_primary_username" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/primary-username"
  description = "RDS primary cluster (${var.aws_primary_region}) master username for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.primary_cluster.master_username
}

resource "aws_ssm_parameter" "second_secondary_username" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/secondary-username"
  description = "RDS secondary cluster (${var.aws_secondary_region}) master username for ${var.global_prefix}"
  type = "SecureString"
  value = aws_rds_cluster.secondary_cluster.master_username
}

resource "aws_ssm_parameter" "second_primary_password" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/primary-password"
  description = "RDS primary cluster (${var.aws_primary_region}) password for ${var.global_prefix}"
  type = "SecureString"
  value = var.master_password
}

resource "aws_ssm_parameter" "second_secondary_password" {
  provider = aws.second
  name = "/${var.global_prefix}/rds-global/secondary-password"
  description = "RDS secondary cluster (${var.aws_secondary_region}) password for ${var.global_prefix}"
  type = "SecureString"
  value = var.master_password
}