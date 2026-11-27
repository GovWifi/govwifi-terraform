# GovWifi Automate Cert Rotation Module

## What is it?

This module creates a scheduled AWS CodeBuild job that checks nightly whether the RADIUS certificate is due to expire. When renewal is due, the module uses Certbot with [DigiCert’s ACME service](https://docs.digicert.com/en/trust-lifecycle-manager/automate-management-of-certificates/acme-automation-service.html) and a Route 53 DNS challenge to download a replacement.  SNS then emails a notification with the certificate’s fingerprint and expiry date. The job runs every week day at midnight UTC.


## Prerequisites

Please ensure the following are added to your AWS environment before running this code:

### Secret Manager 

| Name | Used for |
|---|---|
| `cert_rotate/cert_domain` | The domain that the digicert certificate was issued for (`CERT_DOMAIN`) |
| `cert_rotate/acme_email` | Group email address that recieves the ACME Digicert updates, and also email to recieve notifications from codebuild job when cert renews |
| `cert_rotate/acme_directory_url` | Digicert ACME API directory URL |
| `cert_rotate/acme_eab_kid` | Digicert ACME API ACME External Account Binding key ID |
| `cert_rotate/acme_eab_hmac_key` | Digicert ACME API ACME External Account Binding HMAC key |
| `cert_rotate/order_id` | DigiCert order ID |

### Parameter Store

| Name | Used for |
|---|---|
| `/govwifi-terraform/frontend-certs-bucket` | Name of the London S3 Bucket where certs are stored |

## To do before promoting to prod:

- [ ] Ensure replication to Dublin is working
- [ ] Update cert path to correct folder (currently this points to a testing folder) 
- [ ] Change from dev order id in secrets to real one