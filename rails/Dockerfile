FROM public.ecr.aws/docker/library/ruby:3.2.2-slim as builder
WORKDIR /app

RUN apt-get update -qq && apt-get upgrade -y -qq
RUN apt-get install -y -qq build-essential

RUN bundle config --global frozen 1

COPY Gemfile Gemfile.lock /app/
RUN bundle install

FROM public.ecr.aws/docker/library/ruby:3.2.2-slim
WORKDIR /app

RUN apt-get update -qq && apt-get upgrade -y -qq

COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . /app/
