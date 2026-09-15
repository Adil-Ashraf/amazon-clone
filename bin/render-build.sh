#!/usr/bin/env bash
# Build script run by Render for each deploy.
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
