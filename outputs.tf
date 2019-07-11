output "name" {
  value       = module.kinesis.name
  description = "Name of the stream"
}

output "arn" {
  value       = module.kinesis.arn
  description = "ARN of the stream"
}
