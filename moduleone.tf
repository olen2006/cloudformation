####################
#VARS
####################

variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {
    default = "Ohio"
}

###################
#PROVIDERS
###################

provider "aws"{
    access_key="${var.aws_access_key}"
    secret_key="${var.aws_secret_key}"
    region="us-east-2"
}
###################
#RESOURCES
###################

resources "aws_instance" "nginx" {
    ami           =   "ami-02f706d959cedf892"
    instance_type =   "t2.micro"
    key_name      =   "${var.key_name}"
    
    connection {
        user    =   "ec2-user"
        private_key =  "${file(var.private_key_path)}"
    }
provisioner "remote-exec" {
    inline  =   [
        #Use shell script if it's a big chunk of code.
        "sudo yum install nginx -y",
        "sudo service nginx start"
      ]
    }
}
###################
#RESOURCES
###################

output "aws_instance_public_dns" {
  value = "${aws_instance.nginx.public_dns}"
}

