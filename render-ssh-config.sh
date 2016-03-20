#!/bin/bash

sed -e "s/DEPLOY_ENV/${1}/g" ssh.config.template > ssh.config
