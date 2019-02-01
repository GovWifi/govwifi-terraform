# Important - zone IDs can be obtained from the management console.
# List hosted zones menu -> right hand side.

# CNAME for the database for this environment
resource "aws_route53_record" "db" {
  count   = "${var.db-instance-count}"
  zone_id = "${var.route53-zone-id}"
  name    = "db.${lower(var.aws-region-name)}.${var.Env-Subdomain}.service.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.db.address}"]
}

# CNAME for the DB read replica for this environment
resource "aws_route53_record" "rr" {
  count   = "${var.db-replica-count}"
  zone_id = "${var.route53-zone-id}"
  name    = "rr.${lower(var.aws-region-name)}.${var.Env-Subdomain}.service.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.read_replica.address}"]
}

resource "aws_route53_record" "users-db" {
  count   = "${var.db-instance-count}"
  zone_id = "${var.route53-zone-id}"
  name    = "users-db.${lower(var.aws-region-name)}.${var.env}.wifi.service.gov.uk"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_db_instance.users_db.address}"]
}

