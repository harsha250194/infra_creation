data "aws_route53_zone" "zoneid" {
  provider = aws.r53
  name = local.domain_name
  private_zone = false
}
