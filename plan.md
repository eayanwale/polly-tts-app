# Polly TTS App - Terraform Reference Plan

Region: us-east-1 (N. Virginia)

Pulled from your two docs: the STEPS log (your actual build, your resource names) and V1 (the tutorial you followed, has the JSON and Python you pasted in). Names below use your STEPS log where the two differ.

## Resource List

| Resource | Name | Notes |
|---|---|---|
| DynamoDB table | `posts` | Partition key: `id` (String). Default settings. |
| S3 bucket (website) | `stack-enoch-polly-website` | ACLs enabled, public access NOT blocked, static site hosting, bucket policy for public GetObject |
| S3 bucket (mp3) | `stack-enoch-polly-mp3` | ACLs enabled, public access NOT blocked, same settings as website bucket |
| SNS topic | `new_posts` | Standard type. No manual subscription, Lambda subscribes as trigger. |
| IAM policy | `LambdaPolicyForPolly` | See JSON below |
| IAM role | `LambdaRoleForPolly` | Trusted entity: AWS service, Lambda. Has `LambdaPolicyForPolly` attached |
| Lambda | `PostReader_NewPosts` | Runtime Python 3.14, role `LambdaRoleForPolly` |
| Lambda | `PostReader_ConvertToAudio` | Runtime Python 3.14, role `LambdaRoleForPolly`, timeout 5 min, SNS trigger on `new_posts` |
| Lambda | `PostReader_GetPosts` | Runtime Python 3.14, role `LambdaRoleForPolly` |
| API Gateway REST API | `PostReaderAPI` | Stage: `DEV`. Root resource `/` has GET and POST methods, CORS enabled |

## IAM Policy JSON (LambdaPolicyForPolly)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "polly:SynthesizeSpeech",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "sns:Publish",
        "s3:PutObject",
        "s3:PutObjectAcl",
        "s3:GetBucketLocation",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": ["*"]
    }
  ]
}
```

## S3 Website Bucket Policy (public read)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": ["s3:GetObject"],
      "Resource": ["arn:aws:s3:::stack-enoch-polly-website/*"]
    }
  ]
}
```

## Lambda: PostReader_NewPosts

Env vars: `DB_TABLE_NAME=posts`, `SNS_TOPIC=<arn of new_posts topic>`

```python
import boto3
import os
import uuid

def lambda_handler(event, context):
    recordId = str(uuid.uuid4())
    voice = event["voice"]
    text = event["text"]

    print('Generating new DynamoDB record, with ID: ' + recordId)
    print('Input Text: ' + text)
    print('Selected voice: ' + voice)

    # Creating new record in DynamoDB table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DB_TABLE_NAME'])
    table.put_item(
        Item={
            'id': recordId,
            'text': text,
            'voice': voice,
            'status': 'PROCESSING'
        }
    )

    # Sending notification about new post to SNS
    client = boto3.client('sns')
    client.publish(
        TopicArn=os.environ['SNS_TOPIC'],
        Message=recordId
    )

    return recordId
```

Test event:
```json
{
  "voice": "Mike",
  "text": "Hello Stack Certified Solutions Architects!"
}
```

## Lambda: PostReader_ConvertToAudio

Env vars: `DB_TABLE_NAME=posts`, `BUCKET_NAME=stack-enoch-polly-mp3`
Trigger: SNS topic `new_posts`
Timeout: 5 minutes

```python
import boto3
import os
from contextlib import closing
from boto3.dynamodb.conditions import Key, Attr

def lambda_handler(event, context):
    postId = event["Records"][0]["Sns"]["Message"]
    print("Text to Speech function. Post ID in DynamoDB: " + postId)

    # Retrieving information about the post from DynamoDB table
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DB_TABLE_NAME'])
    postItem = table.query(
        KeyConditionExpression=Key('id').eq(postId)
    )
    text = postItem["Items"][0]["text"]
    voice = postItem["Items"][0]["voice"]
    rest = text

    # Polly synthesize_speech handles ~1500 chars per call, so split
    # the post into blocks of roughly 1000 characters.
    textBlocks = []
    while (len(rest) > 1100):
        begin = 0
        end = rest.find(".", 1000)
        if (end == -1):
            end = rest.find(" ", 1000)
        textBlock = rest[begin:end]
        rest = rest[end:]
        textBlocks.append(textBlock)
    textBlocks.append(rest)

    # For each block, invoke Polly, which transforms text into audio
    polly = boto3.client('polly')
    for textBlock in textBlocks:
        response = polly.synthesize_speech(
            OutputFormat='mp3',
            Text=textBlock,
            VoiceId=voice
        )

        # Save the audio stream to Lambda's /tmp. If there are multiple
        # blocks, they get appended into a single file.
        if "AudioStream" in response:
            with closing(response["AudioStream"]) as stream:
                output = os.path.join("/tmp/", postId)
                with open(output, "ab") as file:
                    file.write(stream.read())

    s3 = boto3.client('s3')
    s3.upload_file('/tmp/' + postId, os.environ['BUCKET_NAME'], postId + ".mp3")
    s3.put_object_acl(ACL='public-read', Bucket=os.environ['BUCKET_NAME'], Key=postId + ".mp3")

    location = s3.get_bucket_location(Bucket=os.environ['BUCKET_NAME'])
    region = location['LocationConstraint']
    if region is None:
        url_begining = "https://s3.amazonaws.com/"
    else:
        url_begining = "https://s3-" + str(region) + ".amazonaws.com/"

    url = url_begining + str(os.environ['BUCKET_NAME']) + "/" + str(postId) + ".mp3"

    # Updating the item in DynamoDB
    response = table.update_item(
        Key={'id': postId},
        UpdateExpression="SET #statusAtt = :statusValue, #urlAtt = :urlValue",
        ExpressionAttributeValues={':statusValue': 'UPDATED', ':urlValue': url},
        ExpressionAttributeNames={'#statusAtt': 'status', '#urlAtt': 'url'},
    )
    return
```

Note: the URL-building block in your doc has a stray line continuation on the `region is not None` branch (an `\` left dangling after `url_begining = ...`). Worth double checking against your actual deployed code before porting.

## Lambda: PostReader_GetPosts

Env vars: `DB_TABLE_NAME=posts`

```python
import boto3
import os
from boto3.dynamodb.conditions import Key, Attr

def lambda_handler(event, context):
    postId = event["postId"]
    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DB_TABLE_NAME'])

    if postId == "*":
        items = table.scan()
    else:
        items = table.query(
            KeyConditionExpression=Key('id').eq(postId)
        )

    return items["Items"]
```

Test event: `{"postId": "*"}`

## API Gateway (PostReaderAPI)

- REST API, resource `/`
- GET method: Lambda proxy is NOT used here, it's a custom integration with a query string param and mapping template (see below), integrated with `PostReader_GetPosts`
- POST method: integrated with `PostReader_NewPosts`
- CORS enabled on GET, POST, OPTIONS
- GET method request: URL query string parameter `postId`
- GET integration request mapping template (`application/json`):
```json
{
  "postId": "$input.params('postId')"
}
```
- Deployed to stage `DEV`, produces an Invoke URL used as `API_ENDPOINT` in the website JS

## Things to double check before writing Terraform

- Exact DynamoDB billing mode (default settings in console = on-demand/PAY_PER_REQUEST unless you changed it)
- Whether S3 buckets need `aws_s3_bucket_public_access_block` explicitly disabled (all four block-public-access settings off) plus `aws_s3_bucket_ownership_controls` set to allow ACLs (`BucketOwnerPreferred` per your STEPS doc)
- Lambda runtime: your STEPS doc says Python 3.14 for all three functions, confirm that's actually available/what you want to pin in Terraform (may want 3.12 or 3.13 depending on current AWS support)
- The API Gateway GET method integration type: this is a non-proxy Lambda integration (custom mapping template), not `AWS_PROXY`, since there's a query string mapping template step. POST method integration type isn't detailed in either doc, worth confirming whether it's proxy or also templated
- SNS topic ARN for `SNS_TOPIC` env var, and actual region/account ID to build into ARNs