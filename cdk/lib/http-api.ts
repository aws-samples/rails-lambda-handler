import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import * as apigwv2 from '@aws-cdk/aws-apigatewayv2-alpha';
import * as apigwv2_integ from '@aws-cdk/aws-apigatewayv2-integrations-alpha';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import { Platform } from 'aws-cdk-lib/aws-ecr-assets';

import * as path from 'path';

export interface HttpApiConstructProps {
  /** RAILS_MASTER_KEY */
  railsMasterKey: string,
}

/**
 * CDK construct to create API Gateway HTTP API with Lambda proxy integration 2.0
 */
export class HttpApiConstruct extends Construct {
  /**
   * Create API Gateway HTTP API with Lambda proxy integration 2.0
   */
  constructor(scope: Construct, id: string, props: HttpApiConstructProps) {
    super(scope, id);

    // Rails HTTP API container image with AWS Lambda Ruby Runtime Interface Client
    const apiContainerImage = lambda.DockerImageCode.fromImageAsset(path.join(__dirname, '../../rails'), {
      platform: Platform.LINUX_ARM64,
      ignoreMode: cdk.IgnoreMode.DOCKER,

      entrypoint: [
        '/usr/local/bundle/bin/aws_lambda_ric',
      ],
      cmd: [
        'lambda_http.handler',
      ],
    });

    // Environment variables for Rails REST API container
    const apiContainerEnvironment = {
      BOOTSNAP_CACHE_DIR: '/tmp/cache',
      RAILS_ENV: 'production',
      RAILS_MASTER_KEY: props.railsMasterKey,
      RAILS_LOG_TO_STDOUT: '1',
    };

    // Lambda function for Lambda proxy integration of AWS API Gateway HTTP API
    const apiFunction = new lambda.DockerImageFunction(this, 'ApiFunction', {
      architecture: lambda.Architecture.ARM_64,
      memorySize: 2048,

      code: apiContainerImage,
      environment: apiContainerEnvironment,

      timeout: cdk.Duration.minutes(1),
      tracing: lambda.Tracing.ACTIVE,
    });

    // AWS API Gateway HTTP API using Rails as Lambda proxy integration
    const railsHttpApi = new apigwv2.HttpApi(this, 'Api', {
      apiName: 'RailsHttpApi',
      defaultIntegration: new apigwv2_integ.HttpLambdaIntegration('RailsHttpApiProxy', apiFunction, {
        payloadFormatVersion: apigwv2.PayloadFormatVersion.VERSION_2_0,
      }),
    });

    new cdk.CfnOutput(this, 'HttpApiUrl', {
      value: railsHttpApi.url!,
    });
  }
}
