# SSM managed instance core
# resource "aws_iam_role_policy_attachment" "ssm_agent" {
#   for_each = module.eks.self_managed_node_groups
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   role       = each.value.iam_role_name
# }

#worker_iam_role_name deprecated from output attachment is now on eks module creation
# => iam_role_additional_policies