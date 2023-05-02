resource "aws_autoscaling_group_tag" "autoscaling_group_tag" {
  # Create a tuple in a map for each ASG tag combo
  for_each = merge([
    for eks_mng, tags in local.eks_autoscaling_group_tags : {
      for tag_key, tag_value in tags : "${eks_mng}-${substr(tag_key, 25, -1)}" => {
        mng   = eks_mng,
        key   = tag_key,
        value = tag_value
      }
    }
  ]...)
  # Lookup the ASG name for the MNG, error if there is more than one
  autoscaling_group_name = one(module.eks.eks_managed_node_groups[each.value.mng].node_group_autoscaling_group_names)
  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = true
  }
}