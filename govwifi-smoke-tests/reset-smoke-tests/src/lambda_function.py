import json
import os
import sys
import boto3
import pymysql
import traceback
import datetime
from typing import Any
import logging
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# --- Configuration ---
# Your secret name (as provided in your request)
SECRET_NAME = os.environ['ADMIN_DB_SM_PATH']
# Your AWS Region (Lambda often infers this, but it's good practice to define or get it)
REGION_NAME = "eu-west-2"
# --- End Configuration ---

# Smoke Test user details
gw_user = os.environ['GW_USER']
gw_pass = os.environ['GW_PASS']
gw_super_user = os.environ['GW_SUPER_ADMIN_USER']
gw_super_pass = os.environ['GW_SUPER_ADMIN_PASS']

aws_region = "eu-west-2"

def get_db_connection_details(secret_name, region_name):
    """
    Retrieves the database connection details from AWS Secrets Manager.

    :param secret_name: The name or ARN of the secret.
    :param region_name: The AWS region where the secret is stored.
    :return: A dictionary containing host, username, password, dbname, and port, or None on failure.
    """

    # 1. Initialize the Secrets Manager client
    try:
        session = boto3.session.Session()
        client = session.client(
            service_name='secretsmanager',
            region_name=region_name
        )
    except Exception as e:
        logger.error(f"Error initializing AWS client for Secrets Manager: {e}")
        return None

    # 2. Call the Secrets Manager API
    try:
        logger.info(f"Attempting to retrieve secret: {secret_name}")
        get_secret_value_response = client.get_secret_value(SecretId=secret_name)

    except ClientError as e:
        # Handle specific Secrets Manager API errors
        error_code = e.response['Error']['Code']

        if error_code == 'DecryptionFailureException':
            logger.error("Secrets Manager: KMS decryption failure. Check KMS key permissions.")
        elif error_code == 'InternalServiceError':
            logger.error("Secrets Manager: An internal service error occurred.")
        elif error_code == 'InvalidParameterException':
            logger.error("Secrets Manager: Invalid parameter in the request.")
        elif error_code == 'InvalidRequestException':
            logger.error("Secrets Manager: Invalid request, potentially due to resource being deleted.")
        elif error_code == 'ResourceNotFoundException':
            logger.error(f"Secrets Manager: The requested secret '{secret_name}' was not found.")
        elif error_code == 'AccessDeniedException':
             # This is a critical error if your IAM policy is incorrect
            logger.error("Secrets Manager: Access Denied. Check the IAM policy for secretsmanager:GetSecretValue.")
        else:
            logger.error(f"Secrets Manager ClientError: {error_code}: {e}")

        # In all failure cases above, we stop execution and return None
        return None

    # 3. Process the secret value
    try:
        # Secrets Manager returns the JSON payload as a string under 'SecretString'
        if 'SecretString' in get_secret_value_response:
            secret_string = get_secret_value_response['SecretString']
            secret_dict = json.loads(secret_string)
        else:
            # Handle binary secrets, though RDS secrets are typically strings
            logger.error("Secret is in binary format, expected string/JSON format.")
            return None

        # 4. Extract and validate required keys
        details = {
            "host": secret_dict["host"],
            "username": secret_dict["username"],
            "password": secret_dict["password"],
            "dbname": secret_dict["dbname"],
            # Ensure port is an integer
            "port": int(secret_dict["port"])
        }

        logger.info("Successfully extracted database connection details.")
        return details

    except json.JSONDecodeError:
        logger.error("Error: Could not decode SecretString into JSON format.")
    except KeyError as e:
        logger.error(f"Error: Required key {e} missing from the secret JSON payload.")
    except ValueError as e:
        logger.error(f"Error: Port value could not be converted to integer. {e}")
    except Exception as e:
        logger.error(f"An unexpected error occurred during secret processing: {e}")

    return None

def get_smoke_users_status(connection):
    status = []

    with connection.cursor() as cursor:
        query = r"""SELECT
            id,
            email,
            failed_attempts,
            locked_at,
            second_factor_attempts_count
        FROM
            users
        WHERE
            email IN ('govwifi-tests@digital.cabinet-office.gov.uk', 'govwifi-tests+superadmin@digital.cabinet-office.gov.uk' );
        """.strip()
        cursor.execute(query)

        for row in cursor.fetchall():
            uid, email, failed_attempts, locked_at, second_factor_attempts_count = row
            status.append(
                dict(uid=uid, email=email, failed_attempts=failed_attempts, locked_at=locked_at, second_factor_attempts_count=second_factor_attempts_count)
            )

    return status



def fix_user_2fa_lockouts(connection):
    with connection.cursor() as cursor:
        query = r"""UPDATE
            users
        SET
            second_factor_attempts_count = 0
        WHERE
            email IN ( 'govwifi-tests@digital.cabinet-office.gov.uk', 'govwifi-tests+superadmin@digital.cabinet-office.gov.uk')
        """.strip()
        return dict(rows_affected=cursor.execute(query))


def fix_gw_user_and_super_user_passwords(connection):
    users = [
        dict(
            email=r'govwifi-tests@digital.cabinet-office.gov.uk',
            encrypted_password=r'$2a$11$2oY.L1IsTH96zu6DMPsetuskCNLuqXYiB2Gw7uRcsWGTGWmFoN6re'
        ),
        dict(
            email=r'govwifi-tests+superadmin@digital.cabinet-office.gov.uk',
            encrypted_password=r'$2a$11$8ko2IcYDW8zYP5ks0OcZNehWzcRoxjRgjQp.DC5I05GGcyKgtbQyy'
        )
    ]
    results = []
    for smoke_test_user in users:
        with connection.cursor() as cursor:
            now = datetime.datetime.now().isoformat()
            email = smoke_test_user['email']
            encrypted_password = smoke_test_user['encrypted_password']
            query = f"""UPDATE
                users
            SET
                users.encrypted_password = '{encrypted_password}',
                users.updated_at = '{now}'
            WHERE
                users.email = '{email}'
            """
            results.append(
                dict(
                    email=email,
                    rows_affected=cursor.execute(query)
                )
            )

    return results


def json_response(body: dict[str, Any], status_code: int):
    return {
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json'
        },
        'body': body
    }


def lambda_handler(event, context):
    try:
        db_details = get_db_connection_details(SECRET_NAME, REGION_NAME)
        connection = pymysql.connect(
            host=db_details['host'],
            user=db_details['username'],
            password=db_details['password'],
            db=db_details['host'],
            port=db_details['port']
        )

        before_status = get_smoke_users_status(connection)
        update_result = fix_user_2fa_lockouts(connection)
        after_status = get_smoke_users_status(connection)
        gw_users_fix = fix_gw_user_and_super_user_passwords(connection)


        return json_response(
            body=dict(
		        status="ok",
                before_status=before_status,
                update_result=update_result,
                after_status=after_status,
                gw_users_fix=gw_users_fix,
            ),
            status_code=200
        )

    except Exception as e:
        a, b, tb = sys.exc_info()
        return json_response(
            body={
                "status": "fail",
                "reason": str(e),
                "traceback": traceback.format_tb(tb)
            },
            status_code=500
        )
