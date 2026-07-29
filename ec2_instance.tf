############### ssh Key Pair

resource "aws_key_pair" "abhirajkv_key" {
  key_name   = "abhirajkv"
  public_key = file("id_rsa.pub")
}

############### Main EC2 Instance

resource "aws_instance" "example" {
  metadata_options {
    http_endpoint          = "enabled"
    instance_metadata_tags = "enabled"
  }
  ami           = "ami-02d36f7d2eae66e8f"
  instance_type = "t3.medium"
  primary_network_interface {
    network_interface_id = aws_network_interface.Nic[count.index].id
  }
  key_name = aws_key_pair.abhirajkv_key.key_name
  count    = var.server_count

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
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("id_rsa")
    host        = aws_instance.example[each.key].public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo cat /var/tmp/hosts_append | sudo tee -a /etc/hosts",
      "sudo chmod -R +x /var/tmp/scripts",
      "sudo /var/tmp/scripts/bootstrap.sh",
      "sudo /var/tmp/scripts/cluster_setup.sh",
      "sudo rm -rf /var/tmp/hosts_append"
    ]
  }
}


############### output
output "Public_IP" {
  value = aws_instance.example[*].public_ip
}
