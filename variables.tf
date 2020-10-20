variable "buffer_size" {
  type        = number
  default     = 128
  description = "Buffer incoming data to the specified size, in MBs"
}

variable "buffer_interval" {
  type        = number
  default     = 60
  description = "Buffer incoming data for the specified period of time, in seconds"
}

variable "columns" {
  type = list(object({
    name = string,
    type = string,
  }))
  default     = []
  description = "The columns in the table, where the key is the name of the column and the value the type"
}

variable "error_prefix" {
  type        = string
  default     = "errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}"
  description = "Prefix added to failed records before writing them to S3"
}

variable "glue" {
  type        = string
  default     = false
  description = "If set, create Glue database and tables"
}

variable "name" {
  type        = string
  description = "The name of the stream"
}

variable "kinesis" {
  type        = bool
  default     = true
  description = "If true a kinesis stream will be created"
}

variable "kms_key_arn" {
  type        = string
  description = "The KMS key ARN used to encrypt all data"
}

variable "parquet" {
  type        = bool
  default     = false
  description = "If true the parquet serializer will be used"
}

variable "partition_keys" {
  type = list(object({
    name = string,
    type = string,
  }))
  default = [
    { name = "event_day", type = "date" },
  ]
  description = "The partition_keys in the table, where the key is the name of the partition and the value the type"
}

variable "prefix" {
  type        = string
  description = "Prefix for the objects in S3"
}

variable "prefix_error" {
  type        = string
  description = "Prefix for failed objects in S3"
}

variable "s3" {
  type        = bool
  default     = true
  description = "If true the S3 bucket will be created"
}

variable "s3_bucket_name" {
  type        = string
  default     = null
  description = "The name of the S3 bucket"
}

variable "tags" {
  type        = map(string)
  description = "A mapping of tags to assign to the stream"
}


