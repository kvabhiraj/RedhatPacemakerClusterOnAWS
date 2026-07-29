resource "aws_iam_role" "pacemaker_role" {
  name = "pacemaker-cluster-role"

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

resource "aws_iam_policy" "pacemaker_route_policy" {
  name        = "pacemaker-route-policy"
  description = "Allows Pacemaker to shift the Overlay IP route"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeRouteTables",
          "ec2:ReplaceRoute"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.pacemaker_role.name
  policy_arn = aws_iam_policy.pacemaker_route_policy.arn
}

resource "aws_iam_instance_profile" "pacemaker_profile" {
  name = "pacemaker-instance-profile"
  role = aws_iam_role.pacemaker_role.name
}
