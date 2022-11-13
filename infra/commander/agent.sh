#!/bin/bash

echo 'eval "$(ssh-agent -s)"'
echo 'ssh-add ~/.ssh/commander'
