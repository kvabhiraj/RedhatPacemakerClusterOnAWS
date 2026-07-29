# Server count for the cluster
variable "server_count" {
  type    = number
  default = 2
}
# Security group ports to be opened
variable "sg_port" {
  type    = list(number)
  default = [22, 80, 443, 2224, 3121, 21064, 7630, 9929]
}
variable "heartbeat" {
  type    = list(number)
  default = [5405, 5406, 9929]
}
# Pacemaker VIP configuration
variable "vip_overlay_ip" {
  type    = string
  default = "192.168.2.101/32"
}
