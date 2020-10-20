output "name" {
  value       = var.kinesis ? module.kinesis["create"].name : null
  description = "Name of the stream"
}

output "arn" {
  value       = var.kinesis ? module.kinesis["create"].arn : null
  description = "ARN of the stream"
}
