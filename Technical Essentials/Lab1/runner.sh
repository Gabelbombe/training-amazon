#!/usr/local/bin/bash

## define vars
assets='/tmp/aws-example'
bucket="s3-test-$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 32 |head -n 1)"
storage="REDUCED_REDUNDANCY"
region="us-east-1"

pngs=(api_2x perl_problems exploits_of_a_mom)

## create assets folder and cd
mkdir -p ${assets} && cd $_

## create bucket
aws s3 mb s3://${bucket} --region ${region}

## create dummy data and sync to bucket
## - region: us-east-1 or override
## - acl: allow public reading of file
## - sse: (bool) implement encryption
curl -sSL http://loripsum.net/api >| ipsum.txt
aws s3 sync ${assets}/ipsum.txt s3://${bucket} \
  --region ${region}                           \
  --acl "public-read"                          \
  --sse

mkdir -p {public,logs,images} ## create...

cd images
for xkcd in "${pngs[@]}" ; do
  wget http://imgs.xkcd.com/comics/${xkcd}.png ## download something funny...
done

## recursive sync to folders to bucket
## - region: us-east-1 or override
## - storage: tag as reduced redundancy
## - exclude: do not upload text files
## - acl: allow public reading of file
## - sse: (bool) implement encryption
cd ${assets}
aws s3 sync ${dir} s3://${bucket}             \
  --region ${region}                          \
  --storage-class ${storage}                  \
  --exlude="*.txt"                            \
  --acl "private"                             \
  --sse


  
