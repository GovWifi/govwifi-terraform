#Generate new database credentials for Users Database if new environment, otherwise ignore:
resource "random_password" "users_db_password" {
  length  = 33
  special = false
}

resource "random_password" "users_db_username" {
  length  = 16
  special = false
}

## COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH

resource "aws_secretsmanager_secret" "users_db_credentials" {
  count       = (var.aws_region == "eu-west-2" ? 1 : 0)
  name        = "rds/users-db/credentials"
  description = "User Details database main username and password. Stored as an RDS password."

  tags = {
    Service = "User-Details-DB"
  }

}


resource "aws_secretsmanager_secret_version" "users_db_username_password" {
  # Write password and username to secret so users_db database can be created
  count         = (var.aws_region == "eu-west-2" ? 1 : 0)
  secret_id     = aws_secretsmanager_secret.users_db_credentials[0].id
  secret_string = jsonencode({ "password" : "${random_password.users_db_password.result}", "username" : "${random_password.users_db_username.result}" })

  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }
}

# Once the users_db database has been created update the secret with host etc:

data "aws_secretsmanager_secret_version" "users_db_creds_password_username" {
  count     = (var.aws_region == "eu-west-2" ? 1 : 0)
  secret_id = aws_secretsmanager_secret.users_db_credentials[0].id
}

resource "aws_secretsmanager_secret_version" "users_db_creds_update_existing" {
  count     = (var.aws_region == "eu-west-2" ? 1 : 0)
  secret_id = aws_secretsmanager_secret.users_db_credentials[0].id

  secret_string = jsonencode({ "username" : jsondecode(data.aws_secretsmanager_secret_version.users_db_creds_password_username[0].secret_string)["username"], "password" : jsondecode(data.aws_secretsmanager_secret_version.users_db_creds_password_username[0].secret_string)["password"], "engine" : "${aws_db_instance.users_db[0].engine}", "host" : "${aws_db_instance.users_db[0].address}", "port" : "${aws_db_instance.users_db[0].port}", "dbname" : " ${aws_db_instance.users_db[0].db_name}", "dbInstanceIdentifier" : "${aws_db_instance.users_db[0].id}" })

  #We only want this to be run once when the environment first comes up. Hence we ignore changes every other time
  lifecycle {
    ignore_changes = [
      secret_string
    ]
  }

  depends_on = [
    aws_db_instance.users_db
  ]
}

## END CREATING A NEW ENVIRONMENT FROM SCRATCH


# Referenced by tasks and IAM roles (leaving these values in to make rolling out automated secrets work easier. To be removed at a later date)
data "aws_secretsmanager_secret_version" "users_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.users_db_credentials.id
}

data "aws_secretsmanager_secret" "users_db_credentials" {
  name = "rds/users-db/credentials"
}

#==============#

#Generate new database credentials for Sessions Database if new environment, otherwise ignore


resource "random_password" "sessions_db_password" {
  length  = 32
  special = false
}

resource "random_password" "sessions_db_username" {
  length  = 16
  special = false
}

## COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH


# resource "aws_secretsmanager_secret" "sessions_db_credentials" {
#   count      = (var.aws_region == "eu-west-2" ? 1 : 0)
#   name        = "rds/session-db/credentials"
#   description = "RDS credentials for the Sessions database (username and password). The database is labelled \"wifi\" throughout our infrastructure (e.g., wifi-wifi-db). Only used in London, but required in Ireland for TF reasons."
#   force_overwrite_replica_secret = true


#   tags = {
#     Service = "Session-DB"
#   }
# }

# resource "aws_secretsmanager_secret_version" "sessions_db_username_password" {
#   # Write password and username to secret so sessions_db database can be created
#   count      = (var.aws_region == "eu-west-2" ? 1 : 0)
#   secret_id     = aws_secretsmanager_secret.sessions_db_credentials[0].id
#   secret_string = jsonencode({ "password" : "${random_password.sessions_db_password.result}", "username" : "${random_password.sessions_db_username.result}" })

#   lifecycle {
#     ignore_changes = [
#       secret_string
#     ]
#   }
# }

## Once the sessions_db database has been created update the secret with host etc:
# data "aws_secretsmanager_secret_version" "sessions_db_creds_password_username" {
#   count      = (var.aws_region == "eu-west-2" ? 1 : 0)
#   secret_id = aws_secretsmanager_secret.sessions_db_credentials[0].id
# }


## COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH

# resource "aws_secretsmanager_secret_version" "sessions_db_creds_update_existing" {
#   count      = (var.aws_region == "eu-west-2" ? 1 : 0)
#   secret_id = aws_secretsmanager_secret.sessions_db_credentials[0].id

#   secret_string = jsonencode({ "username" : jsondecode(data.aws_secretsmanager_secret_version.sessions_db_creds_password_username[0].secret_string)["username"], "password" : jsondecode(data.aws_secretsmanager_secret_version.sessions_db_creds_password_username[0].secret_string)["password"], "engine" : "${aws_db_instance.db[0].engine}", "host" : "${aws_db_instance.db[0].address}", "port" : "${aws_db_instance.db[0].port}", "dbname" : " ${aws_db_instance.db[0].db_name}", "dbInstanceIdentifier" : "${aws_db_instance.db[0].id}" })

#   #We only want this to be run once when the environment first comes up. Hence we ignore changes every other time
#   lifecycle {
#     ignore_changes = [
#       secret_string
#     ]
#   }

#   depends_on = [
#     aws_db_instance.db
#   ]
# }

## END CREATING A NEW ENVIRONMENT FROM SCRATCH

data "aws_secretsmanager_secret_version" "session_db_credentials" {
  secret_id = data.aws_secretsmanager_secret.session_db_credentials.id
}

data "aws_secretsmanager_secret" "session_db_credentials" {
  name = "rds/session-db/credentials"
}

data "aws_secretsmanager_secret_version" "recovery_account" {
  count     = var.recovery_backups_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.recovery_account[0].id
}

data "aws_secretsmanager_secret" "recovery_account" {
  count = var.recovery_backups_enabled ? 1 : 0
  name  = "recovery/AccountID"
}

data "aws_secretsmanager_secret_version" "recovery_kms_key" {
  count     = var.recovery_backups_enabled ? 1 : 0
  secret_id = data.aws_secretsmanager_secret.recovery_kms_key[0].id
}

data "aws_secretsmanager_secret" "recovery_kms_key" {
  count = var.recovery_backups_enabled ? 1 : 0
  name  = "recovery/recovery-kms-key-arn"
}
