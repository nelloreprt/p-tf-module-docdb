# docdb=mongodb >>  comes with only ONE_END_POINT
# Steps to be followed in any data_base service of aws
#1. Cluster
#2. Subnet_groups
#3. Cluster_instance

resource "aws_docdb_cluster" "main" {
  cluster_identifier      = "${var.env}-docdb-cluster"
  engine                  = var.engine
  master_username         = data.aws_ssm_parameter.docdb_master_username.value
  master_password         = data.aws_ssm_parameter.docdb_master_password.value
  backup_retention_period = var.backup_retention_period
  preferred_backup_window = var.preferred_backup_window
  skip_final_snapshot     = var.skip_final_snapshot

  # E
  engine_version = "var.engine_version"

  # E
  # referencing back the subnet_group to cluster
  db_subnet_group_name = aws_docdb_subnet_group.main.name

  # E
  kms_key_id           = data.aws_kms_key.by_alias.arn
  storage_encrypted    = "true"
  # as we are using kms_key, data in the database shall be encrypted, by default it is false, we are setting it to be true
}



resource "aws_docdb_subnet_group" "main" {
  name       = "${var.env}-docdb-subnet-group-main"
  subnet_ids = var.db_subnet_ids

  tags = {
    merge (var.tags, Name = "${var.env}-docdb-subnet-group-main")
}



resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = var.count
  identifier         = "${var.env}-docdb-cluster-${count.index}"   # when count_loop is used, to access index_number >> count.index is used
  cluster_identifier = aws_docdb_cluster.main.id
  instance_class     = var.instance_class
}
