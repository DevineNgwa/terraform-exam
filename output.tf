output "public_subnet_ids" {
  value = [
    aws_subnet.public_subnet1.id,
    aws_subnet.public_subnet2.id
  ]
}

output "autoscaling_group_name" {
  value = aws_autoscaling_group.my_asg.name
}

output "load_balancer_dns" {
  value = aws_lb.web_alb.dns_name
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.my_bucket.arn
}

output "db_instance_endpoint" {
  value = aws_db_instance.my_db_instance.endpoint
}