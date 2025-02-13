data "aws_secretsmanager_secret_version" "notify_api_key" {
  secret_id = data.aws_secretsmanager_secret.notify_api_key.id
}

data "aws_secretsmanager_secret" "notify_api_key" {
  name = "admin-api/notify-api-key"
}

data "aws_secretsmanager_secret_version" "zendesk_api_token" {
  secret_id = data.aws_secretsmanager_secret.zendesk_api_token.id
}

data "aws_secretsmanager_secret" "zendesk_api_token" {
  name = "admin-api/zendesk-api-token"
}

data "aws_secretsmanager_secret_version" "key_base" {
  secret_id = data.aws_secretsmanager_secret.key_base.id
}

data "aws_secretsmanager_secret" "key_base" {
  name = "admin-api/secret-key-base"
}

data "aws_secretsmanager_secret_version" "otp_encryption_key" {
  secret_id = data.aws_secretsmanager_secret.otp_encryption_key.id
}

data "aws_secretsmanager_secret" "otp_encryption_key" {
  name = "admin-api/otp-secret-encryption-key"
}

data "aws_secretsmanager_secret_version" "session_db" {
  secret_id = data.aws_secretsmanager_secret.session_db.id
}

data "aws_secretsmanager_secret" "session_db" {
  name = "rds/session-db/credentials"
}

data "aws_secretsmanager_secret_version" "users_db" {
  secret_id = data.aws_secretsmanager_secret.users_db.id
}

data "aws_secretsmanager_secret" "users_db" {
  name = "rds/users-db/credentials"
}

data "aws_secretsmanager_secret_version" "google_service_account_backup_credentials" {
  secret_id = data.aws_secretsmanager_secret.google_service_account_backup_credentials.id
}

data "aws_secretsmanager_secret" "google_service_account_backup_credentials" {
  name = "admin/google-service-account-backup-credentials"
}

data "aws_secretsmanager_secret" "sentry_dsn" {
  name = "sentry/admin_dsn"
}

data "aws_secretsmanager_secret_version" "tools_account" {
  secret_id = data.aws_secretsmanager_secret.tools_account.id
}

data "aws_secretsmanager_secret" "tools_account" {
  name = "tools/AccountID"
}


#Generate new database credentials if new environment, otherwise ignore
resource "random_password" "admin_password" {
  length  = 32
  special = false
}

resource "random_password" "admin_username" {
  length  = 16
  special = false
}

## COMMENT BELOW IN IF CREATING A NEW ENVIRONMENT FROM SCRATCH

# resource "aws_secretsmanager_secret" "admin_credentials" {
#   # Update existing secrets name and import (this will error is secret already exists)
#   name        = "rds/admin-db/credentials"
#   description = "Autogenerated credentials for the Admin database."
# }

# resource "aws_secretsmanager_secret_version" "admin_db_username_password" {
#   # Write password and username to secret so admin database can be created

#   secret_id     = aws_secretsmanager_secret.admin_credentials.id
#   secret_string = jsonencode({ "password" : "${random_password.admin_password.result}", "username" : "${random_password.admin_username.result}" })

#   lifecycle {
#     ignore_changes = [
#       secret_string
#     ]
#   }
# }

## Once the admin database has been created update the secret with host etc:

# data "aws_secretsmanager_secret_version" "admin_creds_password_username" {
#   secret_id = aws_secretsmanager_secret.admin_credentials.id
# }

#
# resource "aws_secretsmanager_secret_version" "admin_creds_update_existing" {
#   secret_id = aws_secretsmanager_secret.admin_credentials.id

#   secret_string = jsonencode({ "username" : jsondecode(data.aws_secretsmanager_secret_version.admin_creds_password_username.secret_string)["username"], "password" : jsondecode(data.aws_secretsmanager_secret_version.admin_creds_password_username.secret_string)["password"], "engine" : "${aws_db_instance.admin_db.engine}", "host" : "${aws_db_instance.admin_db.address}", "port" : "${aws_db_instance.admin_db.port}", "dbname" : " ${aws_db_instance.admin_db.db_name}", "dbInstanceIdentifier" : "${aws_db_instance.admin_db.id}" })

#   #We only want this to be run once when the environment first comes up. Hence we ignore changes every other time
#   lifecycle {
#     ignore_changes = [
#       secret_string
#     ]
#   }

#   depends_on = [
#     aws_db_instance.admin_db
#   ]
# }

## END CREATING A NEW ENVIRONMENT FROM SCRATCH

# Referenced by tasks and IAM roles (leaving these values in to make roling out automated secrets work easier. To be removed at a later date)
data "aws_secretsmanager_secret_version" "admin_db" {
  secret_id = data.aws_secretsmanager_secret.admin_db.id
}

data "aws_secretsmanager_secret" "admin_db" {
  name = "rds/admin-db/credentials"
}
