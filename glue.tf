resource "aws_glue_catalog_database" "default" {
  for_each = local.glue
  name     = replace(var.name, "-", "_")
}

resource "aws_glue_catalog_table" "default" {
  for_each      = local.glue
  name          = aws_glue_catalog_database.default["create"].name
  database_name = aws_glue_catalog_database.default["create"].name

  table_type = "EXTERNAL_TABLE"

  parameters = {
    classification        = "parquet"
    EXTERNAL              = "TRUE"
    "parquet.compression" = "SNAPPY"
  }

  dynamic partition_keys {
    for_each = var.partition_keys
    iterator = partition_key
    content {
      name = partition_key.value.name
      type = partition_key.value.type
    }
  }

  storage_descriptor {
    location      = "s3://${data.aws_s3_bucket.default.id}/${var.prefix}"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "parquet"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    dynamic columns {
      for_each = var.columns
      iterator = column
      content {
        name = column.value.name
        type = column.value.type
      }
    }
  }

  lifecycle {
    ignore_changes = [parameters]
  }
}
