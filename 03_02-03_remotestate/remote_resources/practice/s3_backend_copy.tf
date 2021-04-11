variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "bucket_name" {
  default = "radmay-tfstate-storage"
}

//PROVIDER
provider "aws" {
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
  region = "ap-south-1"
}

//TERRAFORM USER

data "aws_iam_user" "terraform" {
  user_name = "terraform"
}

//S3 bucket
resource "aws_s3_bucket" "radmay-tfstate-storage" {
  bucket = var.bucket_name
  force_destroy = true
  acl = "private"

  versioning {
    enabled = true
  }

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
      "Sid": "Stmt1618138830892",
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.bucket_name}/*",
      "Principal": {
        "AWS": "${data.aws_iam_user.terraform.arn}"
      }
    }
  ]
}
EOF
}

resource "aws_s3_bucket_public_access_block" "radmay-tfstate-storage-policy" {
  bucket = aws_s3_bucket.radmay-tfstate-storage.id

  block_public_acls = true
  block_public_policy = true
  ignore_public_acls = true
  restrict_public_buckets = true
}

//DYNAMO TABLE
resource "aws_dynamodb_table" "tf-db-statelockinfo-storage" {
  name = "radmay-db-store-statelock-info"
  read_capacity = 20
  write_capacity = 20
  hash_key = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

//IAM policy
resource "aws_iam_user_policy" "terraform_user_db_table" {
  name = "terraform"
  user = data.aws_iam_user.terraform.user_name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "dynamodb:*",
      "Effect": "Allow",
      "Resource": [
            "${aws_dynamodb_table.tf-db-statelockinfo-storage.arn}"
      ]
    }
  ]
}
  EOF
}