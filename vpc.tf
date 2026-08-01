
############### Create Network Interface for each instance and attach security groups to it

resource "aws_network_interface" "Nic" {
  count             = var.server_count
  subnet_id         = aws_subnet.Private.id
  private_ips       = ["10.0.3.${count.index + 10}"]
  security_groups   = [aws_security_group.port_whitelisting.id, aws_security_group.AllowICMP.id, aws_security_group.heartbeat_whitelisting.id]
  source_dest_check = false
}

############### Allocate Elastic IP for each instance and attach it to the network interface  

resource "aws_eip" "public_ip" {
  count             = var.server_count
  domain            = "vpc"
  depends_on        = [aws_network_interface.Nic]
  network_interface = aws_network_interface.Nic[count.index].id
  instance          = aws_instance.example[count.index].id
}
############### VPC

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "MyVPC"
  }
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
############### Secondary route table for Private subnet

resource "aws_route_table" "Route_Table" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }
}

############### Associate Private subnet to route table

resource "aws_route_table_association" "Secondary_route_alloc" {
  subnet_id      = aws_subnet.Private.id
  route_table_id = aws_route_table.Route_Table.id
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


