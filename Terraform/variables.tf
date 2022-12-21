variable "k3s_inbound_ports" {
  type = list(
    object
    (
      {
        internal  = number
        external  = number
        protocol  = string
        cidrBlock = string
      }
    )
  )
  default = [
    {
      internal  = 22
      external  = 22
      protocol  = "tcp"
      cidrBlock = "0.0.0.0/0"
    },
    {
      internal  = 80
      external  = 80
      protocol  = "tcp"
      cidrBlock = "0.0.0.0/0"
    },
    {
      internal  = 443
      external  = 443
      protocol  = "tcp"
      cidrBlock = "0.0.0.0/0"
    }
  ]
}