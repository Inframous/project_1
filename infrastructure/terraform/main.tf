resource "aws_instance" "dev_node" {
  instance_type = "t2.micro"
  ami = data.aws_ami.server_ami.id
  
  for_each = var.instance_names
  
  key_name = aws_key_pair.sql_proj1_auth.id
  vpc_security_group_ids = [aws_security_group.sql_proj1_sg.id]
  subnet_id = aws_subnet.sql_proj1_public_subnet.id
  # user_data = file("userdata.tpl")
  private_ip = "10.123.1.${each.key}"
  
  root_block_device {
    volume_size = 10
  }
  
  tags = {
    Name = "${each.value}"
  }
}



resource "local_file" "ansible_inventory_file" {
  content  = templatefile("templates/hosts.tpl", { public_ips = [for instance in aws_instance.dev_node : instance.public_ip] })
  filename = "../ansible/hosts"
}

resource "local_file" "lb_address_file" {
  content  = templatefile("templates/lb.tpl", { content = [aws_lb.sql_proj1_loadbalancer.dns_name] })
  filename = "../ansible/loadbalacer"
}



resource "null_resource" "show_file" {  
  provisioner "local-exec" {
    command = "cat ${local_file.ansible_inventory_file.filename}"
  }
}

