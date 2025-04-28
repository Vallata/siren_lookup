#!/usr/bin/env bash

# Install Node.js (Render n'en a pas par défaut)
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Ensuite, build normalement
bundle exec rails assets:precompile
