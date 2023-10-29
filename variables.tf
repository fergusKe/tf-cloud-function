variable "GCP_PROJECT" {
  description = "GCP Project ID"
  type        = string
  default     = "exercise-291215"
}

variable "GCP_REGION" {
  type    = string
  default = "asia-northeast1"
}

variable "func_name" {
  type    = string
  default = "tf-cloud-function"
}
