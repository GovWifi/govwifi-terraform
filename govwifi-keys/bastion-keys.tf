resource "aws_key_pair" "govwifi-bastion-key-old" {
  key_name   = "govwifi-bastion-key-20181025"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDbbZuuu+9nqiZelsOQd99jiklZLxWpXgD5mN2M2E3Ej9Uk2g6PE+gZJjHo+xDsmDRW0l+/+YMHVKCFjz9PGd3WrYJ/eMC3QvCtdeHGjN5Py5NSJiShDmTN8SnddLnuKZl0s+9u4jnbGaGiwJyQroXBfuUbdSVCu1HvDDW4R1wBZ4xGxoamgy5LtN8ReJPoECt1Odf2yA2S9wq7S806riFUdN4HEOJNsNYZBhFYlfJ7q3x2s5pEJCydB4gYcvnYImg3uPpGpMjqsTk3493p6p3e2GViUvqVLgNfAE5FARAcgy/jtzwwKJspU1W3eZpURELbRJr0c0nvIKs8A1tFZQm3 bastion@govwifi"
}

resource "aws_key_pair" "govwifi-staging-bastion-key" {
  key_name   = "govwifi-staging-bastion-key-20181025"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8WewWSMURrvhOpkS6pqwuQwwGtdSSjfIrAR62LRhuEjhOfPymK4eUCdK1lRQJqc/dIy09oRqaPLxT0UM9/lkwcLpBsu6/pSijNKUkGPEl0fGrzmf2RVqjFM7CSW6zSDTRW19Tn1yHsQE3shGYdVz5VyqAI2ggx/9m0d3kK+1OpJluMdjGTZNBGcs393Liinbtgl+P6BUe5yNZ8E1MTOeB0pMlbOZ5UI20f6iXRcYAkoqm6qPhzhr1Ua1MDgnn9Sd/N8cqAXApkWvYZ34oObEysRD33Qwm4OOb1geklZ8dp4JDmlG7BPkwJ5udkGh75FNmtAnLxILSa8aM+1mbvPNz staging-bastion@govwifi"
}

resource "aws_key_pair" "govwifi-bastion-key" {
  count      = 1
  key_name   = "govwifi-bastion-key-20210630"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDY/Q676Tp5CTpKWVksMPztERDdjWOrYFgVckF9IHGI2wC38ckWFiqawsEZBILUyNZgL/lnOtheN1UZtuGmUUkPxgtPw+YD6gMDcebhSX4wh9GM3JjXAIy9+V/WagQ84Pz10yIp+PlyzcQMu+RVRVzWyTYZUdgMsDt0tFdcgMgUc7FkC252CgtSZHpLXhnukG5KG69CoTO+kuak/k3vX5jwWjIgfMGZwIAq+F9XSIMAwylCmmdE5MetKl0Wx4EI/fm8WqSZXj+yeFRv9mQTus906AnNieOgOrgt4D24/JuRU1JTlZ35iNbOKcwlOTDSlTQrm4FA1sCllphhD/RQVYpMp6EV3xape626xwkucCC2gYnakxTZFHUIeWfC5aHGrqMOMtXRfW0xs+D+vzo3MCWepdIebWR5KVhqkbNUKHBG9e8oJbTYUkoyBZjC7LtI4fgB3+blXyFVuQoAzjf+poPzdPBfCC9eiUJrEHoOljO9yMcdkBfyW3c/o8Sd9PgNufc= bastion@govwifi"
}

