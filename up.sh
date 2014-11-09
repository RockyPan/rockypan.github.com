#! /bin/bash
# add all new files, commit all modifications, and push to github
# suage: up [message]

git add .
msg=${1:-home}
git commit -a -m "$msg"
git push
