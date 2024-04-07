variable "access_key_aws" {
  type = string
}

variable "secret_key_aws" {
  type = string
}

variable "private_key_path" {
  type = string
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.access_key_aws
  secret_key = var.secret_key_aws
}

resource "aws_lightsail_static_ip_attachment" "shadowsocks" {
  static_ip_name = "${aws_lightsail_static_ip.shadowsocks.id}"
  instance_name  = "${aws_lightsail_instance.shadowsocks.id}"
}

resource "aws_lightsail_instance" "shadowsocks" {
  name              = "shadowsocks_instance"
  availability_zone = "ap-northeast-1a"
  blueprint_id      = "ubuntu_18_04"
  bundle_id         = "micro_3_0"

  connection {
    host        = "${self.public_ip_address}"
    type        = "ssh"
    user        = "ubuntu"
    private_key = "${file(var.private_key_path)}"
  }
  provisioner "remote-exec" {
    inline = ["echo 'hello world'"]
  }

  provisioner "local-exec" {
    command = "aws lightsail open-instance-public-ports --instance-name=shadowsocks_instance --port-info fromPort=443,toPort=443,protocol=tcp"
  }

  provisioner "local-exec" {
    command = "ansible-playbook -u ubuntu --private-key ${var.private_key_path} -i '${self.public_ip_address},' ../ansible-playbook/main.yml --ssh-common-args='-o StrictHostKeyChecking=no'"
  }
}

resource "aws_lightsail_static_ip" "shadowsocks" {
  name = "shadowsocks_ip"
}

output "ip_addr" {
  value = "${aws_lightsail_static_ip.shadowsocks.ip_address}"
}
