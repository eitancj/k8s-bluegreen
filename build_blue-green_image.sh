#!/usr/bin/env sh

### Build Image for Blue-Green K8s Deployment ###
#     nginx shows ctr hostname in blue/green    #
#                  EitanCJ 2023                 #
#                  Shell Script                 #
### ----------------------------------------- ###

# constants
sedscript='8-format-html-file.sh'
htmlfile='/usr/share/nginx/html/index.html'
newimg='nginx:bluegreen'

# build custom static html-file
cat <<EOF >index.html
<!DOCTYPE html>
<title>envclr</title>
<html>
<body style="background-color:#FFFFFF;text-align: center;
margin-right: auto; margin-left: auto;margin-top:50px">

<h3>Container Hostname</h3>
<p style="font-size: 50px;">CtrHname</h2>

</body>
</html>
EOF

# create script to make the html file display the hostname assiged to the ctr at startup
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
sed -i "s/envclr/\${CLR}/" $htmlfile
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
docker image build -q -t $newimg . >/dev/null

# show image
docker images $newimg

# clean up
rm $sedscript index.html Dockerfile
