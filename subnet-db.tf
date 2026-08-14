resource "aws_subnet" "db" {
  count  = var.db_subnet ? length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names) : 0
  vpc_id = aws_vpc.default.id

  cidr_block = cidrsubnet(
    aws_vpc.default.cidr_block,
    var.newbits_db,
    count.index + var.db_netnum_offset,
  )

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      "Name"                = "${var.name}-Subnet-DB-${upper(data.aws_availability_zone.az[count.index].name_suffix)}"
      "Scheme"              = "db"
      "EnvName"             = var.name
      "aws-cdk:subnet-name" = "DB"
      "aws-cdk:subnet-type" = "Isolated"
    },
    local.kubernetes_clusters,
    length(var.kubernetes_clusters) != 0 ? { "kubernetes.io/role/internal-elb" = 1 } : {}
  )
}

resource "aws_route_table" "db" {
  count  = var.db_subnet ? 1 : 0
  vpc_id = aws_vpc.default.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-RouteTable-DB"
      "Scheme"  = "db"
      "EnvName" = var.name
    },
  )
}

resource "aws_route_table_association" "db" {
  count          = var.db_subnet ? (length(data.aws_availability_zones.available.names) > var.max_az ? var.max_az : length(data.aws_availability_zones.available.names)) : 0
  subnet_id      = aws_subnet.db[count.index].id
  route_table_id = aws_route_table.db[0].id

  lifecycle {
    ignore_changes        = [subnet_id]
    create_before_destroy = true
  }
}

resource "aws_vpc_endpoint_route_table_association" "db" {
  count           = var.db_subnet && var.vpc_endpoint_s3_gateway ? 1 : 0
  route_table_id  = aws_route_table.db[0].id
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}