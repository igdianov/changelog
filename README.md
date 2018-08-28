# changelog
Basic example of library repo to test `jx stop changelog` issues:

### Summary 
The `jx step changelog --version vX.X.X` command generates release notes that contain only latest release commit tag and single commit before it. All other commits between previous commits are missing in release notes. See https://github.com/igdianov/changelog/releases/tag/v1.0.5 for example. 

The best way that I found so far to get a list of all direct commits on the release branch from history that excludes all commits on pull request branches using rev-list's `--parent` option is as follows:
```sh
export REV=$(git rev-list --tags --max-count=1 --grep ^Release)
export PREVIOUS_REV=$(git rev-list --tags --max-count=1 --skip=1 --grep ^Release)
export REV_TAG=`git describe $REV`
export PREVIOUS_REV_TAG=`git describe $PREVIOUS_REV`
echo Found commits between $PREVIOUS_REV_TAG(\$PREVIOUS_REV) and $REV_TAG(\$REV) tags:
git rev-list $PREVIOUS_REV..$REV --first-parent --pretty
```

and then use the release tag hashes to generate changelog using commands using `make changelog/fix recipe`:
```
jx step changelog --version v$REV_TAG --generate-yaml=false --rev=$REV --previous-rev=$PREVIOUS_REV
```
### Steps to reproduce the behavior
Fork & clone https://github.com/igdianov/changelog

Use GNU Make to generate commit history for the example:
```bash
make checkout 
make commit/fix Update1x
make commit/fix Update2x
make commit/fix Update3x
make version 
make tag 
make changelog
```
The commit history in Git repository is as follows:

![image](https://user-images.githubusercontent.com/20428629/44692243-da1aec00-aa16-11e8-8c2d-4038b2a2f72b.png)

### Jx version

The output of `jx version` is:

```
NAME               VERSION
jx                 1.3.164
jenkins x platform 0.0.2261
kubernetes cluster v1.10.6-gke.1
kubectl            v1.10.0
helm client        v2.10.0+g9ad53aa
helm server        v2.10.0+g9ad53aa
git                git version 2.18.0.windows.1
```

### Kubernetes cluster

What kind of Kubernetes cluster are you using & how did you create it?
N/A

### Operating system / Environment
Windows 10 / Git Bash

### Expected behavior
All commits between tags 1.0.5 and 1.0.6 should be appear in the release notes:

![image](https://user-images.githubusercontent.com/20428629/44692452-ce7bf500-aa17-11e8-9e85-325d9900eed8.png)



### Actual behavior
Only `Release 1.0.6` and `fix: Commit Update2` are listed in the generated changelog:

![image](https://user-images.githubusercontent.com/20428629/44692274-06366d00-aa17-11e8-89c6-89de6fb3a063.png)


