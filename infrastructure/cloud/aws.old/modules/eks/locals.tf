locals {
  tags = {
    project     = "ARMONIK"
    deployed_by = var.account.arn
    resource    = "EKS"
    created     = formatdate("EEE-DD-MMM-YY-hh:mm:ss:ZZZ", tostring(timestamp()))
  }
}