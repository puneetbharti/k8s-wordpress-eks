# Requester's side of the connection.
resource "aws_vpc_peering_connection" "peer" {
  vpc_id        = "${module.app_vpc.vpc_id}"
  peer_vpc_id   = "${module.db_vpc.vpc_id}"
  auto_accept   = false
  tags = {
    Side = "Accepter"
  }
}

# Accepter's side of the connection.
resource "aws_vpc_peering_connection_accepter" "peer" {
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
  auto_accept               = true

  tags = {
    Side = "Accepter"
  }
}


resource "aws_route" "app_private" {
  count = length("${module.app_vpc.private_route_table_ids}")
  route_table_id            = "${module.app_vpc.private_route_table_ids[count.index]}"
  destination_cidr_block    = "${var.db_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "app_public" {
  count = length("${module.app_vpc.public_route_table_ids}")
  route_table_id            = "${module.app_vpc.public_route_table_ids[count.index]}"
  destination_cidr_block    = "${var.db_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "db_private" {
  count = length("${module.db_vpc.private_route_table_ids}")
  route_table_id            = "${module.db_vpc.private_route_table_ids[count.index]}"
  destination_cidr_block    = "${var.app_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}

resource "aws_route" "db_public" {
  count = length("${module.db_vpc.public_route_table_ids}")
  route_table_id            = "${module.db_vpc.public_route_table_ids[count.index]}"
  destination_cidr_block    = "${var.app_cidr}"
  vpc_peering_connection_id = "${aws_vpc_peering_connection.peer.id}"
}
