########################################################################################################################
# Purpose: Module Outputs
# Version: 1.0
# Copyright: BeyondSoft Consulting, Inc
########################################################################################################################
output "primary_cluster_endpoint" {
  value = aws_rds_cluster.primary_cluster.endpoint
}

output "primary_cluster_reader_endpoint" {
  value = aws_rds_cluster.primary_cluster.reader_endpoint
}

output "primary_cluster_port" {
  value = aws_rds_cluster.primary_cluster.port
}

output "secondary_cluster_endpoint" {
  value = aws_rds_cluster.secondary_cluster.endpoint
}

output "secondary_cluster_reader_endpoint" {
  value = aws_rds_cluster.secondary_cluster.reader_endpoint
}

output "secondary_cluster_port" {
  value = aws_rds_cluster.secondary_cluster.port
}

output "use2_cluster_reader_endpoint" {
  value = aws_rds_cluster.use2_cluster.reader_endpoint
}

output "usw1_cluster_reader_endpoint" {
  value = aws_rds_cluster.usw1_cluster.reader_endpoint
}
