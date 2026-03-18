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

resource "aws_network_acl_rule" "in_db_from_world_tcp_return" {
  count      = var.db_subnet ? 1 : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = "1"
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_db_to_private_tcp" {
  count          = var.db_subnet ? length(aws_subnet.db.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 1
  egress         = true
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "in_db_from_world_udp_return" {
  count      = var.db_subnet ? 1 : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = "101"
  egress         = false
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = "1024"
  to_port        = "65535"
}

resource "aws_network_acl_rule" "out_db_to_vpc_udp" {
  count          = var.db_subnet ? 1 : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 101
  egress         = true
  protocol       = "udp"
  rule_action    = "allow"
  cidr_block     = var.vpc_cidr
  from_port      = "53"
  to_port        = "53"
}

resource "aws_network_acl_rule" "in_db_from_world_icmp_reply" {
  count          = var.db_subnet && var.db_nacl_icmp ? 1 : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = "201"
  egress         = false
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 0 # echo reply
  icmp_code      = -1
}

resource "aws_network_acl_rule" "out_db_to_world_icmp" {
  count          = var.db_subnet && var.db_nacl_icmp ? 1 : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = "201"
  egress         = true
  protocol       = "icmp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  icmp_type      = 8 # echo
  icmp_code      = -1
}

resource "aws_network_acl_rule" "in_db_from_db" {    
  count          = var.db_subnet ? length(aws_subnet.db.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 301
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.db[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_db_to_db" {
  count          = var.db_subnet ? length(aws_subnet.db.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 301
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = aws_subnet.db[count.index].cidr_block
}

resource "aws_network_acl_rule" "out_db_to_world_tcp" {
  count          = var.db_subnet ? 1 : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 401
  egress         = false
  protocol       = "tcp"
  from_port      = "443"
  to_port        = "443"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "in_db_from_private" {
  count          = var.db_subnet ? length(aws_subnet.private.*.cidr_block) : 0
  network_acl_id = aws_network_acl.db[0].id
  rule_number    = count.index + 401
  egress         = false
  protocol       = "tcp"
  from_port = var.db_sql_server_port
  to_port   = var.db_sql_server_port
  rule_action    = "allow"
  cidr_block     = aws_subnet.private[count.index].cidr_block
}
