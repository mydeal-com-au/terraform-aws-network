resource "aws_network_acl" "db" {
  count      = var.db_subnet ? 1 : 0
  vpc_id     = aws_vpc.default.id
  subnet_ids = aws_subnet.db.*.id

  tags = merge(
    var.tags,
    {
      "Name"    = "${var.name}-ACL-db"
      "Scheme"  = "db"
      "EnvName" = var.name
    }
  )
}

resource "aws_network_acl_rule" "in_db_from_db" {    
  count          = var.db_subnet ? length(aws_subnet.db.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 101
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.db[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_db_to_db" {
  count          = var.db_subnet ? length(aws_subnet.db.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 101
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.db[count.index].cidr_block
}

resource "aws_network_acl_rule" "in_db_from_private" {
  count          = var.db_subnet ? length(aws_subnet.private.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 201
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_db_to_private" {
  count          = var.db_subnet ? length(aws_subnet.private.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 201
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
}

#############
# S3 Endpoint
#############
resource "aws_network_acl_rule" "in_db_from_s3" {
  count          = var.vpc_endpoint_s3_gateway && var.db_subnet ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 301
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}

resource "aws_network_acl_rule" "out_db_to_s3" {
  count          = var.vpc_endpoint_s3_gateway && var.db_subnet ? length(data.aws_ec2_managed_prefix_list.s3.entries) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 301
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = tolist(data.aws_ec2_managed_prefix_list.s3.entries)[count.index].cidr
  from_port      = 0
  to_port        = 0
}
