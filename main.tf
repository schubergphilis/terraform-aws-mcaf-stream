locals {
  parquet = var.parquet ? { create = true } : {}
}

module "kinesis" {
  source     = "github.com/schubergphilis/terraform-aws-mcaf-kinesis?ref=v0.1.2"
  name       = var.name
  kms_key_id = var.kms_key_id
  tags       = var.tags
}

module "bucket" {
  source     = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.1.4"
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
      "glue:GetTableVersions",
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
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.1.3"
  name                  = "FirehoseS3Role-${var.name}"
  principal_type        = "Service"
  principal_identifiers = ["firehose.amazonaws.com"]
  role_policy           = data.aws_iam_policy_document.firehose_s3_role.json
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
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.1.3"
  name                  = "FirehoseKinesisRole-${var.name}"
  principal_type        = "Service"
  principal_identifiers = ["firehose.amazonaws.com"]
  role_policy           = data.aws_iam_policy_document.firehose_kinesis_role.json
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
    role_arn            = module.firehose_s3_role.arn
    bucket_arn          = module.bucket.arn
    buffer_size         = var.buffer_size
    buffer_interval     = var.buffer_interval
    error_output_prefix = var.error_prefix
    kms_key_arn         = var.kms_key_arn
    prefix              = var.prefix

    dynamic data_format_conversion_configuration {
      for_each = local.parquet

      content {
        enabled = true

        input_format_configuration {
          deserializer {
            open_x_json_ser_de {}
          }
        }

        output_format_configuration {
          serializer {
            parquet_ser_de {}
          }
        }

        schema_configuration {
          database_name = var.glue_database_name
          role_arn      = module.firehose_s3_role.arn
          table_name    = var.glue_table_name
        }
      }
    }

    dynamic processing_configuration {
      for_each = local.parquet

      content {
        enabled = false
      }
    }
  }
}
