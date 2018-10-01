resource "aws_key_pair" "govwifi-key" {
  key_name   = "govwifi-key-20180530"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDJmLa/tF941z6Dh/jiZCH6Mw/JoTXGkILim/bgDc3PSBKXFmBwkAFUVgnoOUWJDXvZWpuBJv+vUu+ZlmlszFM00BRXpb4ykRuJxWIjJiNzGlgXW69Satl2e9d37ZtLwlAdABgJyvj10QEiBtB1VS0DBRXK9J+CfwNPnwVnfppFGP86GoqE2Il86t+BB/VC//gKMTttIstyl2nqUwkK3Epq66+1ol3AelmUmBjPiyrmkwp+png9F4B86RqSNa/drfXmUGf1czE4+H+CXqOdje2bmnrwxLQ8GY3MYpz0zTVrB3T1IyXXF6dcdcF6ZId9B/10jMiTigvOeUvraFEf9fK7 govwifi@govwifi"
}

resource "aws_key_pair" "govwifi-staging-key" {
  key_name   = "govwifi-staging-key-20180530"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC5jsytL0L7huY13GeWQiQJ3ak0y5D3fhZDWaIlkF5nrrplxuURqFutmV4d1qN7ZxxwKedx5lKZOMC6OsqFDZVifzGCv9lkfvGusNsiRfDqQZGcMfZgwUbTO7jwFDcat5rjgKjKGcx7q5YZb74diHITbIarY74WAK6xvvLgRE9UbcmHv216ifnyu0gEJ0SKzIcgXHJsfDX4lImRwpL2Pz992TbaSvKDN8Ueev3LFCZzYrLbqgrP9YtUDmucEVPGf6g0MUdaJYpZ0UlfEzLohVlumwADrA5dJ0uz7FejiZFZPJDHQcaHJMmwwf5GIJO+jhgfPQMNN467QdRzAp7EC+kd staging@govwifi"
}

resource "aws_key_pair" "govwifi-staging-pentest-key" {
  key_name   = "govwifi-staging-pentest-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQD500gCllrWBYXXqszMLGYJ+iZN4B97Pf/FXUS5FKiNP1gK74HhRsn7DQzOBrMAKoOZBaVBpM2jMba/4GRKCB5TYr5Y59xUTvb3bkOS9ZVdGb4ZE107MpqoAn++OElEG0N9e3qPb5AkSYfeEZ6l2SzrY/yFt1LPxqb0Zfyrp9l41MkIdebro85CKbODoNnAUpxVmhoiUG2zSjuA7X5oG5xbObMAdG6+Z89c+Bdzv08SObJt2/ORvVrQXw5IIUE/JfbiWIs3wIn1GJsLffE01o4uxTBDpAQKdjnrcZmsuMuwx0YKh/V3pWsjDO5tgAu997nQLPJuZZZBJ58USSbfEAzY9zNNjuuRUgxOFT8jFEet8yud4WzlN0OL/cFeqvvyj5B2YXdBMdqWBlrq+aZEfVvKRv+/fiLQAbPyVybTBpmOJfxEo6x5H7bKR5EdQwFujlxNmgnC5mFl6NrCEGodeM4h/Cp8n2rpND8VoH8tEaaj4CPu5TEb7tr5AKUGRidZTeNekRffiqNRV62Y1pMY+CcJSxY81gtV/PIhkjqqKHhV4W3kL1iZ6r/NTm3c5g0AiIL1bz1toc/mrg0wT4U+JyI8byZN1RORJUg1VFwuFkFPzTYVNHlzjaCF/h5TA/Kbjx/3mkhnmFldQNUXjwY5FNs1Ji6H28sba6dB/0NKPCLwzw== staging-pentest@govwifi"
}
