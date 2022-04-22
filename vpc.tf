module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 2.0"

  name = local.name
  cidr = var.cidr
  azs = [ "${local.region}a" ]
  private_subnets = [var.private_subnet]
  public_subnets = [var.public_subnet]
  propagate_private_route_tables_vgw = true

  enable_nat_gateway = false
  enable_vpn_gateway = true

  customer_gateways = {
    customer_router = {
      bgp_asn = 65112
      ip_address  = var.customer_router
      type  = "ipsec.1"
      device_name = "Customer Router"
    }
  }

  enable_flow_log = true
  create_flow_log_cloudwatch_log_group = true
  create_flow_log_cloudwatch_iam_role  = true
  flow_log_max_aggregation_interval = 60

  tags = local.global_tags
}

module "vpn_gateway" {
  source  = "terraform-aws-modules/vpn-gateway/aws"
  version = "~> 2.0"

  vpc_id  = module.vpc.vpc_id
  vpn_gateway_id  = module.vpc.vgw_id
  customer_gateway_id = module.vpc.cgw_ids[0]

  local_ipv4_network_cidr = var.ipv4_cidr
  remote_ipv4_network_cidr  = module.vpc.vpc_cidr_block

  vpn_connection_static_routes_only = true
  vpn_connection_static_routes_destinations = [var.ipv4_cidr , module.vpc.vpc_cidr_block]

  # precalculated length of module variable vpc_subnet_route_table_ids
  vpc_subnet_route_table_count = 1
  vpc_subnet_route_table_ids  = module.vpc.private_route_table_ids

  # tunnel inside cidr & preshared keys (optional)
  tunnel1_inside_cidr = var.custom_tunnel1_inside_cidr
  tunnel2_inside_cidr = var.custom_tunnel2_inside_cidr
  tunnel1_preshared_key = var.custom_tunnel1_preshared_key
  tunnel2_preshared_key = var.custom_tunnel2_preshared_key

  tags = local.global_tags
}

module "endpoints" {
  source = "terraform-aws-modules/vpc/aws/modules/vpc-endpoints"
  vpc_id  = module.vpc.vpc_id
  security_group_ids = aws_security_group.vpc_http.id
  
  subnet_ids = [module.vpc.private_subnets,module.vpc.public_subnets]
  endpoints = {
    api_gw = {
      service = "execute-api"
      route_table_ids  =  [module.vpc.private_route_table_ids, module.vpc.public_route_tables_ids]
      policy = aws_api_gateway_rest_api_policy.api_gw_policy.policy
    }
   }
}


resource "aws_security_group" "vpc_http" {
  name_prefix = "${local.name}-vpc_http"
  description = "Allow HTTP inbound traffic"
  vpc_id  = module.vpc.vpc_id

  ingress {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    protocol  = "tcp"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }
}
