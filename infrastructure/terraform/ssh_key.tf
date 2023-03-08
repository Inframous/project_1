resource "aws_key_pair" "sql_proj1_auth" {
  key_name = "sq-proj1-ssh"
  public_key = file(var.public_key)
}