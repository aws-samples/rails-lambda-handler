# AWS Lambda handler sample for Ruby on Rails

This repository includes the following samples.

- AWS Lambda handler function that launches Ruby on Rails (or other [Rack](https://rack.github.io/) compliant) application
  - [/rails/lambda_rest.rb](/rails/lambda_rest.rb) (for API Gateway REST API)
  - [/rails/lambda_http.rb](/rails/lambda_http.rb) (for API Gateway HTTP API)
- Sample application of Ruby on Rails (simple Web API)
  - [/rails](/rails) (Ruby on Rails project root)
  - [/cdk](/cdk) ([AWS CDK](https://github.com/aws/aws-cdk) project root for deployment)

## How to execute your Ruby on Rails application as AWS Lambda function

### 1. Copy function handler code to your project

Simply copy a file corresponding to your API Gateway type to the root directory of your Ruby on Rails project.

- REST API: [/rails/lambda_rest.rb](/rails/lambda_rest.rb)
- HTTP API: [/rails/lambda_http.rb](/rails/lambda_http.rb)

### 2. Create AWS Lambda function

You have two options to create Lambda function.

- [Use ruby runtime of AWS Lambda](https://docs.aws.amazon.com/lambda/latest/dg/lambda-ruby.html)
- [Use container image](https://docs.aws.amazon.com/lambda/latest/dg/ruby-image.html)

In this sample, we provide sample [Dockerfile](/rails/Dockerfile) to build container image of Ruby on Rails.

### 3. Setup Lambda function

Specify handler name as follows:

- REST API: `lambda_rest.handler`
- HTTP API: `lambda_http.handler`

Specify environment variables as follows:

| Key                       | Example |
| ------------------------- | ------- |
| `BOOTSNAP_CACHE_DIR`      | `/tmp/cache` |
| `RAILS_LOG_TO_STDOUT`     | `1` |
| `RAILS_ENV`               | `production` |
| `RAILS_MASTER_KEY`        | Value of your master.key |
| `RAILS_RELATIVE_URL_ROOT` | (Optional) Path prefix of your Rails application |
| ... | Other variables if needed |

## About sample application

Sample application provides simple Web APIs to query fixed database contains 'Hello World' message.

### `GET /messages`

```
[
    {
        "id": 1,
        "text": "Hello, World!",
        "created_at" :"2022-12-15T01:31:59.291Z",
        "updated_at": "2022-12-15T01:31:59.291Z",
        "url": "URL OF THIS MESSAGE"
    }
]
```

### `GET /messages/{id}`

```
{
    "id": 1,
    "text": "Hello, World!",
    "created_at" :"2022-12-15T01:31:59.291Z",
    "updated_at": "2022-12-15T01:31:59.291Z",
    "url": "URL OF THIS MESSAGE"
}
```

## How to deploy sample application

```
cd cdk
npm ci
npx cdk deploy -c railsMasterKey=d1c2ae419e40d2c43006aacdf98cf7f0
```

After waiting for completion, you will see the outputs like below:

```
RailsLambdaStack.HttpHttpApiUrlE6BB121E = https://xxxx.execute-api.ap-northeast-1.amazonaws.com/
RailsLambdaStack.RestRestApiUrl2AB183B3 = https://yyyy.execute-api.ap-northeast-1.amazonaws.com/default/
```

You can test these APIs by using HTTP client such as cURL.

```
curl https://xxxx.execute-api.ap-northeast-1.amazonaws.com/messages

[
    {
        "id": 1,
        "text": "Hello, World!",
        "created_at" :"2022-12-15T01:31:59.291Z",
        "updated_at": "2022-12-15T01:31:59.291Z",
        "url": "https://xxxx.execute-api.ap-northeast-1.amazonaws.com/messages/1"
    }
]
```

```
curl https://yyyy.execute-api.ap-northeast-1.amazonaws.com/default/messages

[
    {
        "id": 1,
        "text": "Hello, World!",
        "created_at": "2022-12-15T01:31:59.291Z",
        "updated_at": "2022-12-15T01:31:59.291Z",
        "url": "https://yyyy.execute-api.ap-northeast-1.amazonaws.com/default/messages/1"
    }
]
```
