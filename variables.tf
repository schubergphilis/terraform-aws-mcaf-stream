variable name {
  type        = string
  description = "The name of the stream"
}

variable buffer_size {
  type        = number
  default     = 1
  description = "Buffer incoming data to the specified size, in MBs"
}

variable buffer_interval {
  type        = number
  default     = 60
  description = "Buffer incoming data for the specified period of time, in seconds"
}

variable kms_key_id {
  type        = string
  description = ""
}

variable kms_key_arn {
  type        = string
  description = "The KMS key ID used to encrypt all data"
}

variable tags {
  type        = map(string)
  description = "A mapping of tags to assign to the stream"
}
