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

data "aws_ssm_parameter" "read_standalone_bool" {
  name       = aws_ssm_parameter.standalone_bool.name
  depends_on = [aws_ssm_parameter.standalone_bool]
}

data "aws_ssm_parameter" "read_standalone_int" {
  name       = aws_ssm_parameter.standalone_int.name
  depends_on = [aws_ssm_parameter.standalone_int]
}

data "aws_ssm_parameter" "read_standard_string" {
  name       = aws_ssm_parameter.standard_string.name
  depends_on = [aws_ssm_parameter.standard_string]
}

data "aws_ssm_parameter" "read_encrypted_secret" {
  name            = aws_ssm_parameter.encrypted_secret.name
  with_decryption = true
  depends_on      = [aws_ssm_parameter.encrypted_secret]
}