variable "instance_names" {
  type = map(string)
  default = {10:"Jenkins_Controller",11: "Prod1",12: "Prod2"}
}

variable "public_key" {
  type = string
  description = "SSH Public key file path, to be placed in the EC2, and enable you to connect to them via ssh"
  default = "../keys/sq-proj1-ssh.pub"
}

variable "s3_bucket_name" {
  type = string
  default = "sq-proj1-bucket"
}