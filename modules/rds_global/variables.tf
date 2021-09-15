########################################################################################################################
# Purpose: Module Variables
# Version: 1.0
# Copyright: BeyondSoft Consulting, Inc
########################################################################################################################

variable "aws_primary_region" {
  description = "primary EC2 Region for the PostgreSQL Global Cluster"
}

variable "aws_secondary_region" {
  description = "secondary EC2 Region for the PostgreSQL Global Cluster"
}

variable "global_prefix" {
  description = "Resource prefixes for the RDS global cluster"
}

variable "env" {
  default     = ""
  description = "environment"
}

variable "primary_vpc_cidr" {
  description = "primary cidr block for rds"
}

variable "secondary_vpc_cidr" {
  description = "secondary cidr block for rds"
}

########################################################################################################################
# PostgreSQL Global Cluster
########################################################################################################################

variable "db_name" {
  description = ""
}

variable "db_engine" {
  description = ""
}

variable "db_engine_version" {
  description = ""
  default     = null
}

variable "storage_encrypted" {
  description = ""
}

variable "backup_retention_period" {

}

# variable "pg_family" {
#   description = ""
# }

# variable "cluster_parameters" {
#   description = "A list of parameters to apply to the DB cluster parameter group"
#   type        = list(map(string))
#   default     = []
# }

# variable "db_parameters" {
#   description = "A list of parameters to apply to the DB parameter group"
#   type        = list(map(string))
#   default     = []
# }

variable "db_engine_mode" {
  description = ""
  default     = null
}

variable "primary_rds_kms_key" {
  description = ""
  default     = null
}

variable "secondary_rds_kms_key" {
  description = ""
  default     = null
}

variable "skip_final_snapshot" {
  description = ""
}

variable "primary_cluster_instance_count" {
  description = ""
}

variable "secondary_cluster_instance_count" {
  description = ""
}

variable "cluster_instance_class" {
  description = ""
}

variable "primary_subnet_ids" {}

variable "secondary_subnet_ids" {}

variable "master_username" {}

variable "master_password" {}

variable "primary_vpc_id" {}

variable "secondary_vpc_id" {}

variable "snapshot_identifier" {}

variable "tags" {}