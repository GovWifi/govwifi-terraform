variable "govwifi_bastion_key_name" {
  description = "Name of the SSH key for the Bastion instance in AWS."
  type        = string
}

variable "govwifi_bastion_key_pub" {
  description = "SSH public key for the Bastion instance."
  type        = string
}
