# AWS Chatbot Slack Notifications

This directory manages the infrastructure for routing AWS alerts, notifications, and monitoring events directly into Slack using **AWS Chatbot** and **Amazon SNS**.

The configuration uses a **DRY (Don't Repeat Yourself)** pattern driven by a dynamic local map and a single `for_each` resource loop. This makes managing, editing, and adding new Slack channel configurations centralized and straightforward.

---

## How It Works

[AWS Event Source]
│ (e.g., CodeBuild failure, CloudWatch Alarm)
▼
[Amazon SNS Topic]
│
▼
[AWS Chatbot Slack Configuration]
│
▼
[Slack Channel]


1. **Event Trigger:** An AWS resource (like CodeBuild or CloudWatch) triggers an event or alarm.
2. **SNS Routing:** The event is published to a dedicated Amazon SNS Topic.
3. **Chatbot Processing:** AWS Chatbot listens to the SNS topic, processes the incoming payload, and securely delivers a formatted message to a specific Slack channel.

---

## Configuration Architecture

All configurations are defined inside the `local.chatbot_configs` map within `main.tf` (or `locals.tf`). Each key in the map represents a distinct logical alerting pipeline:

| Configuration Key | Purpose | Target Channel Variable |
| :--- | :--- | :--- |
| `alert` | High-priority infrastructure and routing failures. | `local.slack_alerts_channel_id` |
| `monitor` | Medium-priority health and capacity updates. | `local.slack_channel_id` |
| `smoke_tests` | Dedicated test suite and deployment validation status. | `local.slack_smoke_tests_channel_id` |

---

## How-To Guides

### 1. How to Add a New Slack Channel Pipeline

To route a new set of alerts to a brand-new Slack channel, follow these steps:

#### Step A: Retrieve the Slack Channel ID
1. Open Slack and navigate to the channel you want to target.
2. Click the channel name at the top of the screen to open its details menu.
3. Scroll to the very bottom of the pop-up window to find and copy the **Channel ID** (it usually starts with a `C`).

#### Step B: Store the Channel ID
Add the channel ID to your environment configuration secrets or local variables (depending on how the project manages secrets/environment definitions):
```hcl
# Example placeholder in locals.tf or secrets
local.slack_new_feature_channel_id = "C0123456789"
Step C: Update the Terraform Map
Open the file containing local.chatbot_configs and append your new channel block to the map:

Terraform
"new_feature" = {
  configuration_name = "govwifi-chatbot-new-feature-configuration"
  slack_channel_id   = local.slack_new_feature_channel_id
  sns_topic_arns     = [
    aws_sns_topic.my_new_feature_sns_topic.arn
  ]
}
Step D: Deploy
Run your standard deployment pipeline:

``` Bash
make development plan
make development apply
```
2. How to Edit or Update an Existing Channel
Adding/Removing SNS Topics
If you create a new alarm or event rule and want it to post to an existing channel (e.g., sending a new type of test failure to the #smoke-tests channel):

Locate the channel's key inside local.chatbot_configs.

Append or remove the SNS Topic ARN within the sns_topic_arns array:

```Terraform
"smoke_tests" = {
  configuration_name = "govwifi-chatbot-smoke-tests-configuration"
  slack_channel_id   = local.slack_smoke_tests_channel_id
  sns_topic_arns     = [
    aws_sns_topic.smoke_tests[0].arn,
    aws_sns_topic.new_api_smoke_tests.arn # <-- Added new topic here
  ]
}
```
Changing the Target Slack Channel
If the team decides to rename or migrate to a new Slack channel:

Fetch the new Channel ID from Slack.

Update the variable or secret tied to that configuration's slack_channel_id.

⚠️ Important Gotchas & Troubleshooting
🔴 Prerequisite: Workspace Authorization
AWS Chatbot requires a one-time manual OAuth handshake between your AWS Account and the Slack Workspace. If this is a brand new AWS account, someone must log into the AWS Console manually once, navigate to AWS Chatbot, click Configure New Client (Slack), and authorize the workspace before Terraform can successfully apply these configurations.

Chatbot is not posting to Slack?
If your EventBridge rules are firing but nothing appears in Slack, verify the following:

Payload Format: AWS Chatbot requires valid JSON. If you are passing custom notifications using an input_transformer on an EventBridge target, it must strictly adhere to the AWS Chatbot Custom Notification Schema, or Chatbot will drop the message.

SNS Topic Policy: Ensure the SNS topic policy grants sns:Publish rights to the AWS service firing the event (events.amazonaws.com or cloudwatch.amazonaws.com).
