variable "name" {
  type = string
}

variable "force_destroy" {
  type    = bool
  default = false
}

variable "region" {
  type = string
}

variable "attach_access_log_delivery_policy" {
  type    = bool
  default = false
}

variable "attach_waf_log_delivery_policy" {
  type    = bool
  default = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
