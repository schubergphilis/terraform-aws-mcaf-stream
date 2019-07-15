module "kinesis" {
  source     = "github.com/schubergphilis/terraform-aws-mcaf-kinesis?ref=v0.1.1"
  name       = var.name
  kms_key_id = var.kms_key_id
  tags       = var.tags
}

module "bucket" {
  source     = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.1.1"
  name       = var.name
  kms_key_id = var.kms_key_id
  tags       = var.tags
}

data "aws_iam_policy_document" "firehose_s3_role" {
  statement {
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [
      var.kms_key_arn
    ]
  }

  statement {
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:AbortMultipartUpload",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "${module.bucket.arn}",
      "${module.bucket.arn}/*"
    ]
  }
}

module "firehose_s3_role" {
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.1.2"
  name                  = "FirehoseS3Role-${var.name}"
  principal_type        = "Service"
  principal_identifiers = ["firehose.amazonaws.com"]
  policy                = data.aws_iam_policy_document.firehose_s3_role.json
  tags                  = var.tags
}

data "aws_iam_policy_document" "firehose_kinesis_role" {
  statement {
    actions = [
      "kinesis:List*",
      "kinesis:Describe*",
      "kinesis:Get*"
    ]
    resources = [
      module.kinesis.arn
    ]
  }

  statement {
    actions = [
      "kms:Decrypt"
    ]
    resources = [
      var.kms_key_arn
    ]
  }
}

module "firehose_kinesis_role" {
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.1.2"
  name                  = "FirehoseKinesisRole-${var.name}"
  principal_type        = "Service"
  principal_identifiers = ["firehose.amazonaws.com"]
  policy                = data.aws_iam_policy_document.firehose_kinesis_role.json
  tags                  = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "default" {
  name        = var.name
  destination = "extended_s3"
  tags        = var.tags

  kinesis_source_configuration {
    kinesis_stream_arn = module.kinesis.arn
    role_arn           = module.firehose_kinesis_role.arn
  }

  extended_s3_configuration {
    role_arn        = module.firehose_s3_role.arn
    bucket_arn      = module.bucket.arn
    kms_key_arn     = var.kms_key_arn
    buffer_size     = var.buffer_size
    buffer_interval = var.buffer_interval
  }
}
