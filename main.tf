locals {
  glue    = var.glue ? { create = true } : {}
  kinesis = var.kinesis ? { create = true } : {}
  parquet = var.parquet ? { create = true } : {}
  s3      = var.s3 ? { create = true } : {}

  parquet_prefix = "year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
}

data "aws_kms_key" "default" {
  key_id = var.kms_key_arn
}

data "aws_s3_bucket" "default" {
  bucket = var.s3_bucket_name == null ? module.bucket["create"].name : var.s3_bucket_name
}

module "kinesis" {
  for_each   = local.kinesis
  source     = "github.com/schubergphilis/terraform-aws-mcaf-kinesis?ref=v0.1.2"
  name       = var.name
  kms_key_id = data.aws_kms_key.default.id
  tags       = var.tags
}

module "bucket" {
  for_each   = local.s3
  source     = "github.com/schubergphilis/terraform-aws-mcaf-s3?ref=v0.1.10"
  name       = var.s3_bucket_name != null ? var.s3_bucket_name : var.name
  kms_key_id = data.aws_kms_key.default.id
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
      data.aws_s3_bucket.default.arn,
      "${data.aws_s3_bucket.default.arn}/*"
    ]
  }
}

module "firehose_s3_role" {
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.3.0"
  name                  = "FirehoseS3Role-${var.name}"
  create_policy         = true
  principal_identifiers = ["firehose.amazonaws.com"]
  principal_type        = "Service"
  role_policy           = data.aws_iam_policy_document.firehose_s3_role.json
  tags                  = var.tags
}

data "aws_iam_policy_document" "firehose_kinesis_role" {
  for_each = local.kinesis

  statement {
    actions = [
      "kinesis:List*",
      "kinesis:Describe*",
      "kinesis:Get*"
    ]
    resources = [
      module.kinesis["create"].arn
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
  for_each              = local.kinesis
  source                = "github.com/schubergphilis/terraform-aws-mcaf-role?ref=v0.3.0"
  create_policy         = true
  name                  = "FirehoseKinesisRole-${var.name}"
  principal_identifiers = ["firehose.amazonaws.com"]
  principal_type        = "Service"
  role_policy           = var.kinesis ? data.aws_iam_policy_document.firehose_kinesis_role["create"].json : null
  tags                  = var.tags
}

resource "aws_kinesis_firehose_delivery_stream" "default" {
  name        = var.name
  destination = "extended_s3"
  tags        = var.tags

  dynamic kinesis_source_configuration {
    for_each = local.kinesis

    content {
      kinesis_stream_arn = module.kinesis["create"].arn
      role_arn           = module.firehose_kinesis_role["create"].arn
    }
  }

  extended_s3_configuration {
    bucket_arn          = data.aws_s3_bucket.default.arn
    buffer_interval     = var.buffer_interval
    buffer_size         = var.buffer_size
    error_output_prefix = "${var.prefix_error}/${local.parquet_prefix}!{firehose:error-output-type}"
    kms_key_arn         = var.kms_key_arn
    prefix              = "${var.prefix}/${local.parquet_prefix}"
    role_arn            = module.firehose_s3_role.arn

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
          database_name = aws_glue_catalog_database.default["create"].name
          role_arn      = module.firehose_s3_role.arn
          table_name    = aws_glue_catalog_table.default["create"].name
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
