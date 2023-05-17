# parameters are created using Terraform
# parameters can be read using Ansible (aws_ssm_lookup) or Terraform(data_source_block

data "aws_ssm_parameter" "docdb_master_username" {
  name = "${var.env}.docdb.master_username"
}

data "aws_ssm_parameter" "docdb_master_password" {
  name = "${var.env}.docdb.master_password"
}

# for doc_db
data "aws_kms_key" "by_alias" {
  key_id = "alias/roboshop"         # "alias/my-key" key_name in aws >> in our case it is "roboshop"
}