 variable "server_port" {
   description = "The port the web server will be listening"
   type        = number
   default     = 80
 }

 variable "elb_port" {
   description = "The port the elb will be listening"
   type        = number
   default     = 80
 }

 variable "vpc_id" {
   description = "vpc id where the asg is launched"
   default     = ""
 }

 variable "ami_id" {
    description = "region where the above VPC is located"
    default     = ""
 }
 
variable "instance_type" {
    description = "region where the above VPC is located"
    default     = "t2.nano"
 }
