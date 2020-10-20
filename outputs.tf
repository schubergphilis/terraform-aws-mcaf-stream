output "arn" {
  value       = var.kinesis ? module.kinesis["create"].arn : null
  description = "ARN of the kinesis stream"
}

output "name" {
  value       = var.kinesis ? module.kinesis["create"].name : null
  description = "Name of the kinesis stream"
}

output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.default.arn
  description = "ARN of the firehose delivery stream"
}

output "firehose_name" {
  value = aws_kinesis_firehose_delivery_stream.default.name
  description = "Name of the firehose delivery stream"
}
