resource "aws_key_pair" "govwifi_bastion_key" {
  key_name   = var.govwifi_bastion_key_name
  public_key = var.govwifi_bastion_key_pub
}
