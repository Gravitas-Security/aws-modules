data "aws_iam_policy_document" "eks_access" {
  statement {
    sid = "eksAccessPolicy"

    actions = [
      "eks:DescribeCluster",
      "eks:ListClusters"
    ]

    resources = [
      "*",
    ]
  }

}
