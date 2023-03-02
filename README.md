# ***Bump the version of AzureCLI***

To bump the version of AZURECLI make the following changes:

## 1. Edit vsts-agent/Dockerfile
- Open the dockerfile and apply the relevant changes
- Raise a PR to be merged

## 2. Run the build task from local
- After the PR gets merged, run the script vsts-agent/blob/master/acr-build-task.sh from local
- Navigate to the Azure portal container registry and confirm a new image has generated under VSTS

## 3. Open cnp-flux-config to the latest version
- After the image generartes, navigate over to cnp-flux-config/tree/master/apps/vsts/vsts and patch the image version (note: there are separate files for sbox and prod).
