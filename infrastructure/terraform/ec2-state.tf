resource "aws_ec2_instance_state" "Jenkins_Controller" {
    instance_id = aws_instance.dev_node["10"].id
    
  state       = var.instance_state
}

resource "aws_ec2_instance_state" "J_Agent" {
    instance_id = aws_instance.dev_node["11"].id
    
  state       = var.instance_state
}

resource "aws_ec2_instance_state" "Prod1" {
    instance_id = aws_instance.dev_node["12"].id
    
  state       = var.instance_state
}
resource "aws_ec2_instance_state" "Prod2" {
    instance_id = aws_instance.dev_node["13"].id
    
  state       = var.instance_state
}


variable "instance_state" {
  type = string
  default = "running"
}

