<div align="center">
  <img src="assets/images/logo/inventree.png" alt="InvenTree logo" width="200" height="auto" />

  
  <h1>Fish Finder</h1>
  

  This is a fork of the amazing [open-source inventree](https://github.com/inventree/inventree) code.
  

## Deploying to the server
It is assumed you have permission to SSH to the AWS instance.  If you don't, you probably shouldn't have it anyway but you can contact Karla.

A script `deploy-package.sh` was created to simplify this process.  It will build the code and publish it to the server.  
You will then have to ssh to the server, where a script `untar-ff.sh` will update and deploy the code.