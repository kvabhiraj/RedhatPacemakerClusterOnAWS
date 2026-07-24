
############### Main

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

  ############ Boot strap

  # Copy local file to remote server path
  #provisioner "file" {
  #  source      = "./.ssh"
  #  destination = "/home/abhirajkv/.ssh"
  #}

  user_data = join("\n", [file("${path.module}/BootStrap.sh"), file("${path.module}/BootStrap1.sh")])

  vpc_security_group_ids = [aws_security_group.port_whitelisting.id, aws_security_group.AllowICMP.id, aws_security_group.heartbeat_whitelisting.id]
  count                  = var.server_count
  tags = {
    Name = "server0${count.index}"
    # Name = "server01"
    # Name = var.servername
  }
  ########## Disk
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }
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
    for_each = var.heartbeet
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

############### EBS volume
resource "aws_ebs_volume" "shared_disk" {
  availability_zone    = "us-east-1b"
  size                 = 10
  type                 = "io2"
  iops                 = 200
  multi_attach_enabled = true
}
resource "aws_volume_attachment" "shared_disk_attach" {
  count       = var.server_count
  device_name = "/dev/sdx"
  volume_id   = aws_ebs_volume.shared_disk.id
  instance_id = element(aws_instance.example.*.id, count.index)
}
############### output
output "Public_IP" {
  value = aws_instance.example[*].public_ip
}
