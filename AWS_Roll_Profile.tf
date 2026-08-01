############### Create IAM policy for Pacemaker to update VPC route tables for Overlay IP failover

resource "aws_iam_policy" "pacemaker_vip_policy" {
  name        = "PacemakerVIPRoutePolicy"
  description = "Allows Pacemaker to update VPC route tables for Overlay IP failover"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:ReplaceRoute",
          "ec2:DescribeRouteTables",
          "ec2:DescribeInstances",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable"
        ]
        Resource = "*"
      }
    ]
  })
}

############### Create an IAM Role for Pacemaker to update VPC route tables for Overlay IP failover

resource "aws_iam_role" "pacemaker_role" {
  name = "PacemakerClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

############### Attach Policy to an IAM Role

resource "aws_iam_role_policy_attachment" "attach_pacemaker_policy" {
  role       = aws_iam_role.pacemaker_role.name
  policy_arn = aws_iam_policy.pacemaker_vip_policy.arn
}

############### Create Instance Profile to attach to EC2 instances

resource "aws_iam_instance_profile" "pacemaker_profile" {
  name = "PacemakerInstanceProfile"
  role = aws_iam_role.pacemaker_role.name
}
