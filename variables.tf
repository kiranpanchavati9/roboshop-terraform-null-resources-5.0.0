variable ami {
  description = "The AMI ID for the EC2 instance"
  type        = string
  default     = "ami-00adafae70b8029d8"
}

variable instance_type {
  description = "The instance type for the EC2 instance"
  type        = string
  default     = "t3.small"
}

variable key_name {
  description = "The key name for the EC2 instance"
  type        = string
  default     = "aws-helpag"
}

variable zone_id {
  description = "The Route 53 zone ID for the frontend application"
  type        = string
  default     = "Z01214421PKKTLXAI5VN5"
}

variable type {
  description = "The record type for the Route 53 record"
  type        = string
  default     = "A"
}

variable ttl {
  description = "The TTL for the Route 53 record"
  type        = number
  default     = 300
}

variable region {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable components {
  description = "The number of EC2 instances to create"
  default     = {
    "frontend" = ""
    "catalogue" = ""
    "cart" = ""
    "user" = ""
    "shipping" = ""
    "payment" = ""
    "mysql" = ""
    "redis" = ""
    "rabbitmq" = ""
    "mongodb" = ""
  }
}

variable iam_instance_profile {
  description = "The IAM instance profile for the EC2 instance"
  type        = string
  default     = "workstation-role"
}