data "aws_ssm_parameter" "tableau_site" {
  name = "/govwifi/metrics/tableau_site"
}

data "aws_ssm_parameter" "tableau_user_email" {
  name = "/govwifi/metrics/tableau_user_email"
}

data "aws_ssm_parameter" "tableau_pat_token_id" {
  name = "/govwifi/metrics/tableau_pat_token_id"
}

data "aws_ssm_parameter" "tableau_pool_id" {
  name = "/govwifi/metrics/tableau_pool_id"
}
