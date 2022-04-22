
variable "cidr"{
    type = string
    default = "10.0.0.0/16"
}
variable "private_subnet"{
    type = string
    default = "10.0.11.0/24"
}
variable "ipv4_cidr"{
    type = string
    default = "172.16.0.0/24"
}
variable "odin_ip"{
    type = string
    default = "10.10.10.1/32"
}
variable "target_ip"{
    type = string
    default = "10.100.20.1/32"
}
variable "customer_router"{
    type = string
    default = "100.100.20.20"
}
variable "custom_tunnel1_inside_cidr"{
    type = string
    default = "169.254.33.88/30"
}
variable "custom_tunnel2_inside_cidr"{
    type = string
    default = "169.254.33.100/30"
}
variable "custom_tunnel1_preshared_key"{
    type = string
    default = "1234567890abcdefghijklmn"
}
variable "custom_tunnel2_preshared_key"{
    type = string
    default = "abcdefghijklmn1234567890"
}

