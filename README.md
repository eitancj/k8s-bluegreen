# Blue-Green Deployment on Kubernetes

![](https://github.com/eitancj/preview_images/blob/main/bluegreen.png?raw=true)

\
Practice blue-green deployment of a simple web app on your local machine using Docker Desktop.

### Tested Tech Stack
- nginx 1.25.2 on Alpine 3.18-slim
- kubernetes v1.25.2
- docker desktop 4.15.0
- macOS X

### Prerequisites
- Docker Desktop with Kubernetes enabled
- Mac\Linux machine


### Run Programme
1a. Clone Repo.

1b. Create a new namespace as an isolated sandbox for this session.
```sh
kubectl create namespace blue-green
```
\
2. Review the blue deployment yaml. Note how the app version is 1.0.\
   This is the stable version of our app - the BLUE version.

\
\
3. Build the app images. It should output two new images, tagged 1.0 and 2.0. 
```sh
chmod u+x ./build_bg_images.sh
./build_bg_images.sh
```

\
4. Deploy the blue pods.
```sh
kubectl apply -f blu-dep.yml -n blue-green
```

\
5. Review the Service yaml; note how it points to the blue pods only.\
   Deploy it.
```sh
kubectl apply -f blugrn-svc.yml -n blue-green
```

\
6. The working "blue" version of the app is up and running.\
   Test it.
```sh
# Test it from your browser
http://localhost:32123

# OR don't even leave the terminal
watch curl http://localhost:32123
```
> The page title should display – "blue - 1.0".  

> Hard-refreshing the page (or waiting 2 secs in *watch*) should alternate between two container hostnames, both of which should be blue at this point.

\
\
7. Review the green deployment yaml.\
   It should be identical to the blue deployment, same image, only green in the labels.

\
\
8. Deploy the green stand-by.
```sh
kubectl apply -f grn-dep.yml -n blue-green
```

\
9. You now have a running identical stand-by.\
   Yet web requests should still only be directed to the blue world.\
   Hard-refresh/curl your localhost at 32123 to make sure of that.
```sh
http://localhost:32123
# OR
watch curl http://localhost:32123
```

\
10. Still skeptical of the green world?\
    Bypass the service selector and verify that the green pods are running app version 1.0.\
    Run this:
```sh
chmod u+x ./expose_green.sh
. ./expose_green.sh
```
> You should see a green 1.0 pod displayed in your browser.  

\
Now delete the temporary service we've just created, and let's move on.
```sh
kubectl delete svc $GREENPOD -n blue-green
```

\
11.  So we have a service that points to our blue deployment, and a green deployment in stand-by.\
    Let's upgrade the green pods to version 2.0 of our app by changing a single line in the green deployment yaml.
```sh
grep 'image:' grn-dep.yml | awk -F '#' '{print $1 " <--before"}' | xargs

sed -i'.orig' 's/1.0/2.0/' grn-dep.yml && rm grn-dep.yml.orig
# get rid of the '.orig' parts if your version of sed doesn't require it

grep 'image:' grn-dep.yml | awk -F '#' '{print $1 " <--after"}' | xargs
```
> You can of course do this manually by editing the yaml file.

\
\
12. Since no requests are being directed to the green world, we should be able to deploy the new app there without affecting our stable blue world (given a robust & agile infrastructure).
```sh
kubectl apply -f grn-dep.yml -n blue-green
```

\
13. Test the new version of the app before we direct users there.\
    In this practice case, we'll settle for browser testing like we did earlier.
```sh
. ./expose_green.sh
```
> You should now see a green *2.0* pod displayed in your browser.  

> Yet if you navigate back to http://localhost:32123, you'll see that users our still only being directed to the blue 1.0 app.

\
Delete the temporary service we've just created.
```sh
kubectl delete svc $GREENPOD -n blue-green && unset GREENPOD && unset GREENPORT
```

\
14. Update the Service yaml from blue to green.
```sh
grep 'env:' blugrn-svc.yml | awk -F '#' '{print $1 " <--before"}' | xargs

sed -i'.orig' 's/blue/green/' blugrn-svc.yml && rm blugrn-svc.yml.orig
# get rid of the '.orig' parts if your version of sed doesn't require it

grep 'env:' blugrn-svc.yml | awk -F '#' '{print $1 " <--after"}' | xargs
```

\
15. OK, everything's set – time to do the switch.\
   Henceforth, all new web requests will be directed to the new version of the app – to the green world.
```sh
kubectl apply -f blugrn-svc.yml -n blue-green
```

\
16. Test your main app at 32123. Should be green and 2.0.
```sh
http://localhost:32123
# OR
watch curl http://localhost:32123
```

\
17.  Alright! All new connections are now using the latest version of our app.\
    But WAIT! there's a problem. Something's not working right for some of the users. SHIT.\
    But why? we tested the new version and deployed it to an identical environment!\
    Who knows; always expect the unexpected when it comes to I.T.\
    \
    Let's implement one of the best features of blue-green deployments – swift rollbacks.
```sh
# change 'green' to 'blue' in the service's yaml file
grep 'env:' blugrn-svc.yml | awk -F '#' '{print $1 " <--before"}' | xargs

sed -i'.orig' 's/green/blue/' blugrn-svc.yml && rm blugrn-svc.yml.orig
# # get rid of the '.orig' parts if your version of sed doesn't require it

grep 'env:' blugrn-svc.yml | awk -F '#' '{print $1 " <--after"}' | xargs


# apply changes — revert back to the blue world with the old version of the app
kubectl apply -f blugrn-svc.yml -n blue-green
```

\
18. Quick, test your main app at 32123!\
   Should have now gone back to blue and 1.0.
```sh
http://localhost:32123
# OR
watch curl http://localhost:32123
```
> Good. All users report that the app is now functioning properly.  

> We'll need to investigate why this happened, and perhaps implement more strenuous CI/CD pipeline testing before attempting the update again.

\
19. That's it! Let's get your machine back to the way it was, cleanup time.


### Cleanup
1. Delete the blue-green namespace and all its resources along with it.
```sh
kubectl delete ns blue-green
```
2. Remove the docker images we've created at the beginning of our session.
```sh
docker rmi bgdeploy:1.0 bgdeploy:2.0
```
3. Thanks for your time.


### Notes
1. After a successful blue-green deployment is achieved, you may tear down the blue environment (ideally with an IaC tool).\
   When the time comes to do another update, you may mount a blue stand-by, and repeat the same process only from green to blue, ending up with a blue 3.0 version, for example.\
   And so on and so forth.

2. If you have access to a load-balanced cloud k8s cluster, you could try and change the service type in the yaml file from NodePort to LoadBalancer, and then also make the corresponding changes to your cloud's lb when making the switch.\
   I haven't tried it myself, but I see no reason for it not to work.
   
3. Ideally this entire procedure would be done using a comprehensive CI/CD pipeline – a continuous (automatic) blue-green deployment, so to speak.

4. Blue-green deployments entail pros and cons when compared with other deployment methods.\
   I recommend reading up on it, as this example doesn't cover theory nor complex scenarios.

5. In real-world scenarios, blue-green deployments may require further steps to be taken with each update, such as adjusting the configuration of persistent storage, dns, load balancers, databases, etc.