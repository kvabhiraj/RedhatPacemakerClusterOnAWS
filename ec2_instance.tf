############### ssh Key Pair

resource "aws_key_pair" "ec2-user_key" {
  key_name   = "ec2-user_key"
  public_key = file("id_rsa.pub")
}

############### Main EC2 Instance

resource "aws_instance" "example" {
  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
  count                = var.server_count
  ami                  = "ami-02d36f7d2eae66e8f"
  instance_type        = "t3.medium"
  key_name             = aws_key_pair.ec2-user_key.key_name
  iam_instance_profile = aws_iam_instance_profile.pacemaker_profile.name
  primary_network_interface {
    network_interface_id = aws_network_interface.Nic[count.index].id
  }
  root_block_device {
    volume_size = "40"
    volume_type = "gp3"
    encrypted   = true
  }
  tags = {
    Name = "server0${count.index}"
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

############### Collect Cluster node names and route ID cluster configuration 

resource "local_file" "clus_member" {
  filename = "${path.module}/clus_member"
  content  = <<EOT
  %{for instance in aws_instance.example~}
  ${instance.tags.Name}
  %{endfor~}
  EOT
}
resource "local_file" "Route_ID" {
  filename = "${path.module}/Route_ID"
  content  = aws_route_table.Route_Table.id
}

############### Copy File to all instances and update /etc/hosts, instance details for stonith and create cluster 

resource "time_sleep" "wait_30_seconds" {
  depends_on      = [aws_instance.example, aws_eip.public_ip, local_file.instance_details, local_file.clus_member]
  create_duration = "30s"
}

resource "null_resource" "copy_files" {
  depends_on = [time_sleep.wait_30_seconds]
  count      = var.server_count
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id_rsa")
    host        = aws_eip.public_ip[count.index].public_ip
  }
  provisioner "file" {
    source      = "${path.module}/scripts"
    destination = "/var/tmp/"
  }
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
  provisioner "file" {
    source      = "${path.module}/authorized_keys"
    destination = "/var/tmp/authorized_keys"
  }
  provisioner "file" {
    source      = "${path.module}/Route_ID"
    destination = "/var/tmp/Route_ID"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cat /var/tmp/hosts_append | sudo tee -a /etc/hosts",
      "sudo chmod -R +x /var/tmp/scripts",
      "sudo /var/tmp/scripts/bootstrap.sh",
      "sudo /var/tmp/scripts/cluster_setup.sh",
      "sudo rm -rf /var/tmp/hosts_append",
      "sudo mkdir /home/abhirajkv/.ssh",
      "sudo cp /var/tmp/authorized_keys /home/abhirajkv/.ssh/authorized_keys",
      "sudo chmod -R 600 /home/abhirajkv/.ssh",
      "sudo chown -R abhirajkv:abhirajkv /home/abhirajkv",
      "sudo rm -rf /var/tmp/authorized_keys"
    ]
  }
}



############### VIP Route for Pacemaker Cluster

# 1.Create the placeholder route for your Virtual IP

resource "aws_route" "pacemaker_vip_route" {
  depends_on             = [time_sleep.wait_30_seconds]
  network_interface_id   = aws_network_interface.Nic[0].id
  route_table_id         = aws_route_table.Route_Table.id
  destination_cidr_block = "192.168.100.100/32"
  # Prevents Terraform from reversing Pacemaker's route changes during failovers
  lifecycle {
    ignore_changes = [
      network_interface_id
    ]
  }
}

############### output
output "Public_IP" {
  depends_on = [time_sleep.wait_30_seconds]
  value      = aws_instance.example[*].public_ip
}
