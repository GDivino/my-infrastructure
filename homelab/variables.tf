variable "tenancy_ocid" {
  type = string
}

variable "user_ocid" {
  type = string
}

variable "private_key_password" {
  type      = string
  sensitive = true
}

variable "private_key_path" {
  type      = string
  sensitive = true
}

variable "fingerprint" {
  type      = string
  sensitive = true
}

variable "compartment_id" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "wireguard_public_key_path" {
  type      = string
  sensitive = true
}

variable "wireguard_private_key_path" {
  type      = string
  sensitive = true
}

variable "n8n_public_key_path" {
  type      = string
  sensitive = true
}

variable "n8n_private_key_path" {
  type      = string
  sensitive = true
}
