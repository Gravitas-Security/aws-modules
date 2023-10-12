module "iam" {
    source = "../../aws-iam"

    roles = {
        "eks-admin" = {
            trusted_entity = "arn:aws:iam::123456789321:root"
            policies = [
                "AdministratorAccess",
                "eks-admin-policy"
                ]
            }
            "eks-admin-node-role" = {
            trusted_entity = "ec2.amazonaws.com"
            instance_profile = true
            policies = [
                "eks-admin-policy"
                ]
            }
    }

    policies = {
        "eks-admin-policy" = {
            description = "policy for eks access"
            statement = [
                {
                    sid = "eksadmin"
                    effect = "Allow"
                    actions = [
                        "eks:*"
                    ]
                    resources = [
                        "*"
                    ]
                }
            ]
        }
    }
     
}