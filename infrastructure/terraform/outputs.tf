output "public_ips" {
  value = [for instance in aws_instance.dev_node : instance.public_ip]
}

output "lb_ip" {
  value = aws_lb.sql_proj1_loadbalancer.dns_name
}