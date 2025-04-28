#!/usr/bin/env bash
set -o errexit

bundle config set force_ruby_platform true
bundle install
bundle exec rake assets:precompile
bundle exec rake assets:clean
bundle exec rake db:migrate
