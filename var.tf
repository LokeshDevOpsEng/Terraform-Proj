variable "cidr" {
  default = "10.0.0.0/16"
}
variable "sub1-cidr" {
  default = "10.0.0.0/24"
}
variable "sub2-cidr" {
  default = "10.0.4.0/24"
}
variable "available-zone-1" {
  default = "ap-south-1a"
}
variable "available-zone-2" {
  default = "ap-south-1b"
}
variable "ami-id" {
  default = "ami-007020fd9c84e18c7"
}
variable "instance-type" {
  default = "t2.micro"
}
variable "key_pair" {
  default = "terraformkeypair"
}