import json
import os
import sys
import boto3
import pymysql
import traceback
import datetime
from typing import Any

# RDS settings
db_hostname = os.environ['DB_HOST']
db_name = os.environ['DB_NAME']
db_pass = os.environ['DB_PASS']
db_user_name = os.environ['DB_USER']
db_port = 3306

# Smoke Test user details
gw_user = os.environ['GW_USER']
gw_pass = os.environ['GW_PASS']
gw_super_user = os.environ['GW_SUPER_ADMIN_USER']
gw_super_pass = os.environ['GW_SUPER_ADMIN_PASS']

aws_region = "eu-west-2"


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
        connection = pymysql.connect(
            host=db_hostname,
            user=db_user_name,
            password=db_pass,
            db=db_name,
            port=db_port
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
            status_code=400
        )
