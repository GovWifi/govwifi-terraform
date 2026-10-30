data "aws_ssm_parameter" "read_native_list" {
  name       = aws_ssm_parameter.native_list.name
  depends_on = [aws_ssm_parameter.native_list]
}

data "aws_ssm_parameter" "read_json_map" {
  name       = aws_ssm_parameter.json_map.name
  depends_on = [aws_ssm_parameter.json_map]
}

data "aws_ssm_parameter" "read_json_nested" {
  name       = aws_ssm_parameter.json_nested.name
  depends_on = [aws_ssm_parameter.json_nested]
}
