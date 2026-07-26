############### ssh Key Pair

resource "aws_key_pair" "abhirajkv_key" {
  key_name   = "abhirajkv"
  public_key = file("id_rsa.pub")
}
############### VPC

resource "aws_vpc" "my_vpc" {
  cidr_block         = "10.0.0.0/16"
  enable_dns_support = true
}
resource "aws_subnet" "Private" {
  vpc_id            = aws_vpc.my_vpc.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.3.0/24"
}
############### Internet GW

resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.my_vpc.id
}
############### Secondary route table for IGW

resource "aws_route_table" "Secondary" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

############### Associate Public subnet to Second_route

resource "aws_route_table_association" "Secondary_route_alloc" {
  subnet_id      = aws_subnet.Private.id
  route_table_id = aws_route_table.Secondary.id
}

############### Security Group

resource "aws_security_group" "port_whitelisting" {
  vpc_id = aws_vpc.my_vpc.id
  dynamic "ingress" {
    for_each = var.sg_port
    content {
      description = "Allow Incoming traffic on port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
resource "aws_security_group" "AllowICMP" {
  vpc_id = aws_vpc.my_vpc.id
  ingress {
    description = "Allow ICMP"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "heartbeat_whitelisting" {
  vpc_id = aws_vpc.my_vpc.id
  dynamic "ingress" {
    for_each = var.heartbeat
    content {
      description = "Allow Incoming traffic on port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
############### Main EC2 Instance

resource "aws_instance" "example" {
  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
  ami                         = "ami-02d36f7d2eae66e8f"
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.Private.id
  private_ip                  = "10.0.3.${count.index + 10}"
  associate_public_ip_address = true
  key_name                    = aws_key_pair.abhirajkv_key.key_name
  vpc_security_group_ids      = [aws_security_group.port_whitelisting.id, aws_security_group.AllowICMP.id, aws_security_group.heartbeat_whitelisting.id]
  count                       = var.server_count

  tags = {
    Name = "server0${count.index}"
  }
  ############### Bootstrap

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id_rsa")
    host        = self.public_ip
  }

  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/var/tmp/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod -R +x /var/tmp/scripts",
      "sudo /var/tmp/scripts/bootstrap.sh",

    ]
  }
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

}

############### Generate /etc/hosts file

resource "local_file" "hosts_cfg" {
  content = templatefile("${path.module}/scripts/hosts.tpl", {
    count_nb = length(aws_instance.example)
    ips      = aws_instance.example[*].private_ip
    names    = aws_instance.example[*].tags.Name
  })
  filename = "${path.module}/hosts_append"
}

############### Collect Instance ID for stonith

resource "local_file" "instance_details" {
  filename = "${path.module}/instances"
  content  = <<EOT
  %{for instance in aws_instance.example~}
  ${instance.tags.Name}:${instance.id}
  %{endfor~}
  EOT
}

############### Collect Cluster node names for cluster configuration

resource "local_file" "clus_member" {
  filename = "${path.module}/clus_member"
  content  = <<EOT
  %{for instance in aws_instance.example~}
  ${instance.tags.Name}
  %{endfor~}
  EOT
}

############### Copy File to all instances and update /etc/hosts, instance details for stonith and create cluster 

resource "null_resource" "copy_files" {
  depends_on = [local_file.hosts_cfg, local_file.instance_details, local_file.clus_member]
  for_each   = { for idx, instance in aws_instance.example : idx => instance }
  provisioner "file" {
    source      = "${path.module}/hosts_append"
    destination = "/var/tmp/hosts_append"
  }
  provisioner "file" {
    source      = "${path.module}/instances"
    destination = "/var/tmp/instances"
  }
  provisioner "file" {
    source      = "${path.module}/clus_member"
    destination = "/var/tmp/clus_member"
  }
  provisioner "file" {
    source      = "${path.module}/aASKey"
    destination = "/var/tmp/aASKey"
  }
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id_rsa")
    host        = each.value.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cat /var/tmp/hosts_append | sudo tee -a /etc/hosts",
      "sudo /var/tmp/scripts/cluster_setup.sh",
      "sudo rm -rf /var/tmp/hosts_append"
    ]
  }
}

############### output
output "Public_IP" {
  value = aws_instance.example[*].public_ip
}
