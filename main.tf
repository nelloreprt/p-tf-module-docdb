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

  vpc_security_group_ids = [aws_security_group.main.id]
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

#------- Creating Parameters for DOCDB

# docdb_url for CATALOGUE_component (login to catalogue_component >> open cat /app/server.js)
resource "aws_ssm_parameter" "docdb_url_catalogue" {
  name  = "${var.env}.docdb.url.catalogue"
  type  = "String"

  # from developers code server.js >>
  value = "mongodb://${data.aws_ssm_parameter.docdb_master_username.value}:${data.aws_ssm_parameter.docdb_master_pasword.value}@${aws_docdb_cluster.main.endpoint}:27017/catalogue?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
} # for reference from aws >> mongodb://${data.aws_ssm_parameter.docdb_master_username.value}:${data.aws_ssm_parameter.docdb_master_password.value}@${aws_docdb_cluster.main.endpoint}:27017/catalogue?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"

# docdb_url for USER_component (login to user_component >> open cat /app/server.js)
resource "aws_ssm_parameter" "docdb_url_user" {
  name  = "${var.env}.docdb.url.user"
  value = "mongodb://${data.aws_ssm_parameter.docdb_master_username.value}:${data.aws_ssm_parameter.docdb_master_password.value}@${aws_docdb_cluster.main.endpoint}:27017/users?tls=true&replicaSet=rs0&readPreference=secondaryPreferred&retryWrites=false"
  type  = "String"
}

resource "aws_ssm_parameter" "docdb_endpoint" {
  name  = "${var.env}.docdb.endpoint"
  type  = "String"
  value = aws_docdb_cluster.main.endpoint
}

# note: docdb username:password are already created using aws_ssm_parameters
# so we are not creating docdb username:password again

#--------------------------------------------------------------------------------------------------------------
#idea >> we are creating Security_Group
#        allowing app_subnets
#        attaching security_group back to database

# Security_Group for DOCDB
resource "aws_security_group" "main" {
  name        = "docdb-${var.env}-sg"
  description = "docdb-${var.env}-sg"
  vpc_id      = var.vpc_id


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "DOCDB"
    from_port        = 27017           # inside DOCDB we are opening port 27017
    to_port          = 27017           # inside DOCDB we are opening port 27017
    protocol         = "tcp"
    cidr_blocks      = var.cidr_block     # here we have to specify which (app)subnet should access the docdb (not in terms of subnet_id, but in terms of cidr_block)
  }

  tags = {
    merge (var.tags, Name = "docdb-${var.env}-security-group")
}
