variable "aws_key_pair" {
    default = "D:/Ethans AWS/Practice/awsPracticeKey.pem"
}

variable "mybkt" {
  default="mybucket03032022"
}

variable "vpc_cidr" {
  default=["10.10.0.0/16"]
}

# Defining CIDR Block for 1st Subnet
variable "subnet_cidr" {
  default = "10.10.1.0/24"
}