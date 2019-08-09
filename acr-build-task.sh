#!/bin/sh

ACR_NAME=hmctspublic  # The name of your Azure container registry
PROJECT_NAME=vsts-agent
GIT_USER=hmcts  # Your GitHub user account name
GIT_PAT=$(az keyvault secret show --vault-name infra-vault-prod --name hmcts-github-apikey --query value -o tsv)

az acr task create \
    --registry $ACR_NAME \
    --name $PROJECT_NAME \
    --image hmcts/$PROJECT_NAME:{{.Run.ID}} \
    --context https://github.com/$GIT_USER/$PROJECT_NAME.git \
    --branch master \
    --file Dockerfile \
    --git-access-token $GIT_PAT \
    --subscription DCD-CNP-PROD
