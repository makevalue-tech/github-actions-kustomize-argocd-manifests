#!/bin/bash

printf "\033[0;32m============> Adding SSH deploy key \033[0m\n"
git config --global core.sshCommand "ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
eval `ssh-agent -s`
echo "$4" > ssh-key
chmod 400 ssh-key
ssh-add ssh-key

if [[ "$GITOPS_BRANCH" == "sandbox" ]]; then
    printf "\033[0;36m================================================================================================================> Condition 2: sandbox environment \033[0m\n"
    printf "\033[0;32m============> Cloning $6 - Branch: sandbox \033[0m\n"
    git clone $7 -b sandbox
    cd $6
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    echo "Repo $6 cloned!!!"

    printf "\033[0;32m============> Sandbox branch Kustomize step - Sandbox overlay \033[0m\n"
    cd k8s/$1/overlays/sandbox
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Git commit and push \033[0m\n"
    cd ../..
    git commit -am "$3 has Built a new version: $RELEASE_VERSION"
    git push origin sandbox

elif [[ "$GITOPS_BRANCH" == "release" ]]; then
    printf "\033[0;36m================================================================================================================> Condition 3: New release (Sandbox and Production environment) \033[0m\n"
    printf "\033[0;32m============> Cloning $6 - Branch: $GITOPS_BRANCH \033[0m\n"
    git clone $7 -b sandbox
    cd $6
    git config --local user.email "action@github.com"
    git config --local user.name "GitHub Action"
    echo "Repo $6 cloned!!!"

    printf "\033[0;32m============> Develop branch Kustomize step - Sandbox Overlay \033[0m\n"
    cd k8s/$1/overlays/sandbox
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Develop branch Kustomize step - Production overlay \033[0m\n"
    cd ../prod
    kustomize edit set image IMAGE=$2/$1:$RELEASE_VERSION
    echo "Done!!"

    printf "\033[0;32m============> Git commit and push: Branch sandbox \033[0m\n"
    cd ../..
    git commit -am "$3 has Built a new version: $RELEASE_VERSION"
    git push origin sandbox

    printf "\033[0;32m============> Open PR: sandbox -> master \033[0m\n"
    export GITHUB_TOKEN=$5
    gh pr create --head sandbox --base master -t "GitHub Actions: Automatic PR opened by $3 - $RELEASE_VERSION" --body "GitHub Actions: Automatic PR opened by $3 - $RELEASE_VERSION"

fi
