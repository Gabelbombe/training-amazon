#!/usr/local/bin/bash
# AWS Tech Essentials Lab1 in code

# CPR : Jd Daniel :: Ehime-ken
# MOD : 2015-11-17 @ 14:42:21
# VER : 1.0.0


## unused, might implement....
#[ -z "${1}" ] && { echo "AWS Profile must be specified" ; exit 1 ; }
#[ -z "${2}" ] && { echo "AWS Region must be specified"  ; exit 1 ; }
#aws="aws --profile ${1} --region ${2}"  ## prepackage the aws command


# # # # # # # # # # # # # # #
# # # # # # # # # # # # # # #
# # # # # # # # # # # # # # #


## define vars
assets='/tmp/aws-example'
bucket="s3-test-$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 32 |head -n 1)"
storage="REDUCED_REDUNDANCY"

pngs=(api_2x perl_problems exploits_of_a_mom)

## create assets folder and cd
mkdir -p ${assets} && cd $_

## create bucket
aws s3 mb s3://${bucket} --region ${region}

## create dummy data and sync to bucket
## - acl: allow public reading of file
## - sse: (bool) implement encryption
curl -sSL http://loripsum.net/api >| ipsum.txt
aws s3 sync ${assets}/ipsum.txt s3://${bucket} \
  --acl "public-read"                          \
  --sse

mkdir -p {public,logs,images} ## create...

cd images
for xkcd in "${pngs[@]}" ; do
  wget http://imgs.xkcd.com/comics/${xkcd}.png ## download something funny...
done

## recursive sync to folders to bucket
## - storage: tag as reduced redundancy
## - exclude: do not upload text files
## - acl: allow public reading of file
## - sse: (bool) implement encryption
cd ${assets}
aws s3 sync ${dir} s3://${bucket}             \
  --storage-class ${storage}                  \
  --exlude="*.txt"                            \
  --acl "private"                             \
  --sse

## create an s3 policy for the bucket
echo '{
  "Version":"2012-10-17",
  "Statement":[
    {
      "Sid":"AddPerm",
      "Effect":"Allow",
      "Principal": "*",
      "Action":["s3:GetObject"],
      "Resource":["arn:aws:s3:::#REPLACEMENT#"]
    }
  ]
}' |sed -e "s/#REPLACEMENT#/${bucket}\/images\/*/g" > policy.json

## apply policy to the bucket
aws s3api put-bucket-policy --bucket ${bucket} --policy file://policy.json

## clean up the project
## - force: we're serious
aws s3 rm s3://${bucket} --force


############################
##    extra cred stuff    ##
##    ................    ##
############################


## redefine bucket-name
bucket="serverlogs-$(cat /dev/urandom |tr -dc 'a-zA-Z0-9' |fold -w 32 |head -n 1)"

## create bucket
aws s3 mb s3://${bucket} --region ${region}

## nor positive if expiry is correct?
## also id might need to be:  archive-logs
echo '{
  "Rules": [
    {
      "ID": "Move to Glacier after thirty days (objects in logs/)",
      "Prefix": "logs/",
      "Status": "Enabled",
      "Transition": {
        "Days": 30,
        "StorageClass": "GLACIER"
      }
    },
    {
      "ID": "Delete logs after ninety days",
      "Prefix": "logs/",
      "Status": "Enabled",
      "Expiration": {
        "Days": 90
      },
    }
  ]
}' > lifecycle.json

## same as rule apply target etc..
aws s3api put-bucket-lifecycle --bucket ${bucket} --lifecycle-configuration file://lifecycle.json

## clean up the project
## - force: we're serious
aws s3 rm s3://${bucket} --force
rm -fr ${assets}
