variable "server_count" {
  type    = number
  default = 2
}

variable "sg_port" {
  type    = list(number)
  default = [22, 80, 443, 2224, 3121, 21064, 7630, 9929]
}
variable "heartbeet" {
  type    = list(number)
  default = [5405, 5406, 9929]
}
