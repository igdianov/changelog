CURRENT=$(pwd)
NAME := $(APP_NAME)
OS := $(shell uname)

RELEASE_BRANCH := "master"
RELEASE_VERSION := $(shell cat VERSION)
RELEASE_ARTIFACT := org.example:upstream
RELEASE_GREP_EXPR := '^[Rr]elease'

export PREFIX
export VERSION

.PHONY: all

# If the first argument is "commit"...
ifeq (commit,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  FILE := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(FILE):;@:)
endif

# # If the first argument is "run"...
# ifeq (run,$(firstword $(MAKECMDGOALS)))
#   # use the rest as arguments for "run"
#   RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
#   # ...and turn them into do-nothing targets
#   $(eval $(RUN_ARGS):;@:)
# endif
#
# prog: # ...
# 	# ...
# run : prog
# 	@echo prog $(RUN_ARGS)
#

all: ;

# dependency on .PHONY prevents Make from 
# thinking there's `nothing to be done`
version/preview: .PHONY
	$(eval VERSION = $(shell echo $(PREVIEW_VERSION)))	

version/release: .PHONY
	$(eval VERSION = $(shell echo $(RELEASE_VERSION)))

git-rev-list: .PHONY
	$(eval REV = $(shell git rev-list --tags --max-count=1 --grep $(RELEASE_GREP_EXPR)))
	$(eval PREVIOUS_REV = $(shell git rev-list --tags --max-count=1 --skip=1 --grep $(RELEASE_GREP_EXPR)))
	$(eval REV_TAG = $(shell git describe ${PREVIOUS_REV}))
	$(eval PREVIOUS_REV_TAG = $(shell git describe ${REV}))
	@echo Found commits between $(PREVIOUS_REV_TAG) and $(REV_TAG) tags:
	git rev-list $(PREVIOUS_REV)..$(REV) --first-parent --pretty

credentials:
	git config --global credential.helper store
	jx step git credentials

checkout: #credentials
	# ensure we're not on a detached head
	git checkout $(RELEASE_BRANCH) 

skaffold/%: version/%
	${MAKE} skaffold

skaffold:
	@echo doing skaffold docker build with tag=$(VERSION)
	#skaffold build -f skaffold.yaml 

updatebot/push:
	@echo doing updatebot push $(RELEASE_VERSION)
	#pdatebot push --ref $(RELEASE_VERSION)

updatebot/push-version:
	@echo doing updatebot push-version
	#pdatebot push-version --kind maven $(RELEASE_ARTIFACT) $(RELEASE_VERSION)

updatebot/update:
	@echo doing updatebot update $(RELEASE_VERSION)
	#pdatebot update

updatebot/update-loop:
	@echo doing updatebot update-loop $(RELEASE_VERSION)
	#pdatebot update-loop --poll-time-ms 60000

preview: 
	mvn versions:set -DnewVersion=$(PREVIEW_VERSION)
	mvn install
	${MAKE} skaffold/preview

install: 
	mvn clean install

verify: 
	mvn clean verify

deploy: 
	mvn clean deploy -DskipTests
	${MAKE} skaffold/release

jx-release-version:
	$(shell jx-release-version > VERSION)
	$(eval RELEASE_VERSION = $(shell cat VERSION))
	@echo Using next release version $(RELEASE_VERSION)

version: jx-release-version
	mvn versions:set -DnewVersion=$(RELEASE_VERSION)

changelog/fix: git-rev-list
	@echo Creating Github changelog for release: $(RELEASE_VERSION)
	jx step changelog --version v$(RELEASE_VERSION) --generate-yaml=false --rev=$(REV) --previous-rev=$(PREVIOUS_REV)

changelog:
	@echo Creating Github changelog for release: $(RELEASE_VERSION)
	jx step changelog --version v$(RELEASE_VERSION) --generate-yaml=false

file: 
	touch $(FILE)

commit: file
	git add $(FILE)
	git commit -m '$(PREFIX)Commit $(FILE)' --allow-empty # if first release then no verion update is performed

commit/%: 
	$(eval PREFIX = $(subst commit/, ,$@): )
	$(MAKE) commit $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
	git push

tag: 
	git add --all
	git commit -m "Release $(RELEASE_VERSION)" --allow-empty # if first release then no verion update is performed
	git tag -fa v$(RELEASE_VERSION) -m "Release version $(RELEASE_VERSION)"
	git push origin v$(RELEASE_VERSION)

clean: 
	rm -f VERSION
	mvn clean versions:revert
