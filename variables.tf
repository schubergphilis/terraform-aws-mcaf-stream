variable name {
  type        = string
  description = "The name of the stream"
}

variable buffer_size {
  type        = number
  default     = 128
  description = "Buffer incoming data to the specified size, in MBs"
}

variable buffer_interval {
  type        = number
  default     = 60
  description = "Buffer incoming data for the specified period of time, in seconds"
}

variable error_prefix {
  type        = string
  default     = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}"
  description = "Prefix added to failed records before writing them to S3"
}

variable glue_database_name {
  type        = string
  default     = ""
  description = "The name of the Glue database that contains the schema for the output data"
}

variable glue_table_name {
  type        = string
  default     = ""
  description = "The Glue table that contains the column information that constitutes your data schema"
}

variable kms_key_id {
  type        = string
  description = "The KMS key ID used to encrypt all data"
}

variable kms_key_arn {
  type        = string
  description = "The KMS key ARN used to encrypt all data"
}

variable parquet {
  type        = bool
  default     = false
  description = "If true the parquet serializer will be used"
}

variable prefix {
  type        = string
  default     = "data/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/"
  description = "The time format prefix used for delivered S3 files"
}

variable tags {
  type        = map(string)
  description = "A mapping of tags to assign to the stream"
}
