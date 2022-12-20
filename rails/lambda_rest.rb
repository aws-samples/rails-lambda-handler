require 'json'
require 'rack'
require 'base64'

$app ||= Rack::Builder.parse_file("#{__dir__}/config.ru").first

RELATIVE_URL_ROOT = ENV['RAILS_RELATIVE_URL_ROOT']

def handler(event:, context:)
  # Retrieve HTTP request parameters conforming to Lambda proxy integration input format of AWS API Gateway REST API
  # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-input-format
  httpMethod = event.fetch('httpMethod')
  path = event.fetch('path')
  multiValueQueryStringParameters = event['multiValueQueryStringParameters'] || {}

  requestContext = event.fetch('requestContext')
  protocol = requestContext['protocol'] || 'HTTP/1.1'
  requestTimeEpoch = requestContext['requestTimeEpoch']

  requestHeaders = event.fetch('headers')
  host = requestHeaders['X-Forwarded-Host'] || requestHeaders.fetch('Host')
  port = requestHeaders.fetch('X-Forwarded-Port')
  scheme = requestHeaders['CloudFront-Forwarded-Proto'] || requestHeaders.fetch('X-Forwarded-Proto')

  requestBody = event['body'] || ''
  if event['isBase64Encoded']
    requestBody = Base64.decode64(requestBody)
  end
  requestBodyContent = StringIO.new(requestBody)

  env = {
    Rack::REQUEST_METHOD => httpMethod,
    Rack::SCRIPT_NAME => RELATIVE_URL_ROOT || '',
    Rack::PATH_INFO => path,
    Rack::QUERY_STRING => Rack::Utils.build_query(multiValueQueryStringParameters),
    Rack::SERVER_NAME => host,
    Rack::SERVER_PORT => port,
    Rack::SERVER_PROTOCOL => protocol,

    Rack::RACK_VERSION => Rack::VERSION,
    Rack::RACK_URL_SCHEME => scheme,
    Rack::RACK_INPUT => requestBodyContent,
    Rack::RACK_ERRORS => $stderr,

    # Escape hatch for access to the context and event of Lambda function
    'lambda.context' => context,
    'lambda.event' => event,
  }

  # Add request headers to environment based on Rack specification
  multiValueRequestHeaders = event.fetch('multiValueHeaders')
  multiValueRequestHeaders.each_pair do |key, value|
    name = key.upcase.gsub('-', '_')
    header = case name
      when 'CONTENT_TYPE', 'CONTENT_LENGTH'
        name
      else
        "HTTP_#{name}"
    end
    env[header] = value.join(',')
  end

  env['CONTENT_LENGTH'] ||= requestBodyContent.size.to_s

  env['HTTP_X_REQUEST_ID'] ||= context.aws_request_id
  env['HTTP_X_REQUEST_START'] ||= "t=#{requestTimeEpoch}" if requestTimeEpoch

  begin
    # Execute Rack application and get response
    status, responseHeaders, responseBody = $app.call(env)

    # Build response body
    responseBodyContent = ''

    if responseBody.respond_to?(:each)
      responseBody.each do |item|
        responseBodyContent << item if item
      end
    end
    if responseBody.respond_to?(:close)
      responseBody.close
    end

    # Generate response conforming to REST API output format
    # https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-lambda-proxy-integrations.html#api-gateway-simple-proxy-for-lambda-output-format
    response = {
      'statusCode' => status,
      'body' => responseBodyContent
    }

    # Set single value response headers as 'headers' response field
    # Set multi value response headers as 'multiValueHeaders' response field
    singleValueResponseHeaders = {}
    multiValueResponseHeaders = {}
    responseHeaders&.each { |key, value|
      if value.is_a?(::Array)
        multiValueResponseHeaders[key] = value
      elsif value.is_a?(::String)
        if value.include?("\n")
          multiValueResponseHeaders[key] = value.split("\n")
        else
          singleValueResponseHeaders[key] = value
        end
      end
    }
    if !singleValueResponseHeaders.empty?
      response['headers'] = singleValueResponseHeaders
    end
    if !multiValueResponseHeaders.empty?
      response['multiValueHeaders'] = multiValueResponseHeaders
    end

    return response

  rescue Exception => exception
    return {
      'statusCode' => 500,
      # For debug purpose only. It is not recommended to include error messages in the response body
      'body' => exception.message
    }
  end
end
