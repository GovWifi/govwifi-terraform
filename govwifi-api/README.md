# User Sign Up Lambda

The code for the user signup lambda is kept in this repo:
https://github.com/GovWifi/govwifi-lambda-for-user-signup-api

This code needs to be turned into a zip file and added to this directory. Further instructions can be found in the [repo README](https://github.com/GovWifi/govwifi-lambda-for-user-signup-api).

## Reasons For Adding This Lambda User Sign Up

Previously the User signup API security groups were too open. They were
restricted by port but not by source. It is better to lockdown the ingress
traffic to specific known IPs, rather than to allow traffic from any source to
reach the app. We only want traffic from
Notify(https://www.notifications.service.gov.uk/) and our SNS user signup
notifications topic to reach our User Signup API app.

## How This Works
Restricting traffic that originates from SNS is not a simple task, this is because SNS does not operate inside a VPC, and therefore we cannot simply restrict traffic to a single IP (or small set of IPS). After some discussion we decided the simplest way to
achieve what we wanted, was to add an AWS lambda function between SNS and the
User signup API ECS task. The full details of the conversations with AWS have
been documented in the comment section of the Trello card linked at the bottom
of this message. [There is also an in-depth DRD(Decision Requirements Diagram)]
(https://docs.google.com/document/d/1mQIDjVehcNa13paqjHWGylCVY5RoUcnnif0Uv_5l_Lk/edit#)


## To achieve this the following was added:

- A lambda function, which forwards any messages sent via SNS to the User Sign, and the appropriate IAM roles/permissions to do so.
- A Lambda SNS trigger to replace our current https trigger.
- Three private subnets in the AWS London(eu-west-2) region (one for each
availability zone) that the lambda will exist in.
- Three new NAT gateways (to
allow egress traffic from each of new private subnets to the User Signup API
)
- Three new EIPs for the NAT gateways
- Three route tables (please see [the DRD](https://docs.google.com/document/d/1mQIDjVehcNa13paqjHWGylCVY5RoUcnnif0Uv_5l_Lk/edit?tab=t.0#heading=h.suvkszxbqg7q) for information on why three in particular were necessary)
- New ingress rules to the User Sign Up API security group, allowing traffic from the EIP
associated with the new NAT gateways and Notify’s egress IPs.
