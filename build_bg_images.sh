#!/usr/bin/env bash

### Build Images for Blue-Green K8s Deployment ###
#          nginx, docker, html, bash, sh         #
#                  EitanCJ 2023                  #
### -----------------------------------------  ###

## main purpose
# - Create a docker image of an nginx html page showing the container's
# hostname, for each of the listed app versions.

## features
# 1. Displays ctr hostname in body, stylized with colour according to env
# 2. Displays app version in body, stylized with colour according to env
# 3. Displays environment and app version in page title
# 4. Automatically cleans up after itself
# 5. Shows summarized image details after its creation

# constants
sedscript='8-format-html-file.sh'
htmlfile='/usr/share/nginx/html/index.html'
newimg='bgdeploy'
appvs=('1.0' '2.0')

# main

# build custom html-file
cat <<EOF >index.html
<!DOCTYPE html>
<title>envclr - t_appv</title>
<html>
<body style="background-color:#FFFFFF;text-align: center;
margin-right: auto; margin-left: auto">

<p style="font-size: 25px; margin-top:50px">Container Hostname:</p>
<p style="font-size: 50px; margin-top:0px">CtrHname</p>

<p style="font-size: 25px; margin-top:75px">App Version: b_appv</p>

</body>
</html>
EOF

for appv in "${appvs[@]}"; do
    # create script to update the html file with the relevant env, app version and styling
    cat <<EOF >$sedscript
#!/bin/sh

# get container hostname AND update html file to display it
CTRHNAME=\$(hostname)
sed -i "s/CtrHname/\${CTRHNAME}/" $htmlfile

# get env colour
if grep -q blue $htmlfile ; then
    CLR="blue"
elif grep -q green $htmlfile ; then
    CLR="green"
else
    CLR="BAD_ENV_COLOUR"
fi

# set html style formatting
sSPAN="\\<span style\\=\\"color\\:\${CLR}\\;font-weight\\:bold\\"\\>"
eSPAN="\\<\\/span\\>"

# format colour in html file accordingly
sed -i "s/\${CLR}/\${sSPAN}\${CLR}\${eSPAN}/" $htmlfile
sed -i "s/b_appv/\${sSPAN}${appv}\${eSPAN}/" $htmlfile
sed -i "s/envclr/\${CLR}/" $htmlfile
sed -i "s/t_appv/${appv}/" $htmlfile
EOF

    # create Dockerfile
    cat <<EOF >Dockerfile
FROM nginx:1.25.2-alpine3.18-slim
LABEL maintainer=eitancj

# set vars
ENV INDEX=$htmlfile
ENV ScriptDir=/docker-entrypoint.d/
ENV SedScript=$sedscript

# place custom static html-file for nginx to pick up
COPY index.html \$INDEX

# place script that updates the html-file in nginx's startup-scripts dir
COPY \$SedScript \$ScriptDir\$SedScript
RUN chmod u+x \$ScriptDir\$SedScript
EOF

    # build image quietly
    docker image build -q -t $newimg:$appv . >/dev/null

done

# show images
docker images $newimg

# clean up
rm $sedscript index.html Dockerfile
