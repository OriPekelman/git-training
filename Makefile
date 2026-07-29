.DEFAULT_GOAL := help
SHELL := /bin/bash

HUGO ?= hugo
PYTHON ?= python3

.PHONY: help serve build lint links toc toc-check examples examples-check check clean

help:  ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

serve:  ## Run the site locally with live reload on http://localhost:1313
	$(HUGO) server --buildDrafts --navigateToChanged

build:  ## Build the site into ./public, failing on broken cross-references
	@set -o pipefail; \
	$(HUGO) --gc --minify 2>&1 | tee /tmp/hugo-build.log; \
	if grep -qE "not found in '" /tmp/hugo-build.log; then \
		echo; \
		echo "Broken chapter cross-reference or image (see WARN lines above)."; \
		exit 1; \
	fi

lint:  ## Lint the course content (translation scars, bad commands, dead links)
	$(PYTHON) utilities/lint_docs.py

links:  ## Lint including external URL checks (slow, needs network)
	$(PYTHON) utilities/lint_docs.py --links

toc:  ## Rebuild the landing-page table of contents from chapter front matter
	$(PYTHON) utilities/gen_toc.py

toc-check:  ## Fail if the landing-page table of contents is stale
	$(PYTHON) utilities/gen_toc.py --check

examples:  ## Regenerate the command transcripts in utilities/snippets
	utilities/scenario.sh
	@echo
	@echo "Now look at what changed:  git diff utilities/snippets"

examples-check:  ## Fail if the transcripts are stale for the installed Git
	utilities/scenario.sh --check

check: lint toc-check examples-check build  ## Everything CI should run

clean:  ## Remove build output and scratch repos
	rm -rf public resources/_gen utilities/scratch .hugo_build.lock
