# 1. Define the STONITH IAM Policy Document
data "aws_iam_policy_document" "stonith_policy" {
  statement {
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:RebootInstances",
      "ec2:TerminateInstances",
      "ec2:StopInstances",
      "ec2:StartInstances"

    ]
    resources = ["*"] # Replace with actual instance ARNs or use wildcards

    # Optional: Restrict to specific instances (recommended)
    # condition {
    #   test     = "StringEquals"
    #   variable = "aws:ResourceTag/Cluster"
    #   values   = ["production"]
    # }
  }
}

# 2. Create the IAM Policy in AWS
resource "aws_iam_policy" "stonith_policy" {
  name        = "STONITHPolicy"
  path        = "/"
  description = "Policy for Cluster STONITH (Fencing)"
  policy      = data.aws_iam_policy_document.stonith_policy.json
}

# 3. Create the IAM User for the Cluster
resource "aws_iam_user" "cluster_user" {
  name = "cluster-user"
}

# 4. Attach the Policy to the User
resource "aws_iam_user_policy_attachment" "stonith_attach" {
  user       = aws_iam_user.cluster_user.name
  policy_arn = aws_iam_policy.stonith_policy.arn
}
