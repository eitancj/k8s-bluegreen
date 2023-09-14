#!/usr/bin/env sh

### Build Image for Green-Blue K8s Deployment Practice ###
#       deployment shows the container name              #
#                   Eitan CJ 2023                        #
###                 Shell Script                       ###

# vars
sedscript='8-replace-with-ctrname.sh'
htmlfile='/usr/share/nginx/html/index.html'
newimg='nginx:ctrname'

# build static html file
cat <<EOF >index.html
<!DOCTYPE html>
<title>envclr</title>
<html>
<body>

<h1>Container Hostname:</h1>
<h2> CtrHname</h2>

</body>
</html>
EOF

# create script to update html file so that it displays the ctr name assigned at startup
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
FROM nginx:latest

# set vars
ENV INDEX=$htmlfile
ENV ScriptDir=/docker-entrypoint.d/
ENV SedScript=$sedscript

# place custom static-html file for nginx to pick up
COPY index.html \$INDEX

# place script that updates the html file with the ctr's name in nginx startup-scripts dir
COPY \$SedScript \$ScriptDir\$SedScript
RUN chmod u+x \$ScriptDir\$SedScript
EOF

# build image
docker image build -q -t $newimg . > /dev/null

# show image
docker images $newimg

# clean up
rm $sedscript index.html Dockerfile 