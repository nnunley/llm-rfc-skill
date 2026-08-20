# Conformance for this series. The gate's one body is skill/rfc-check —
# this file, CI, and the README all call it; none reimplement it.

RFC_DIR ?= rfc
SKILL_DEST ?= $(HOME)/.claude/skills/authoring-rfcs

test:
	skill/rfc-check $(if $(FILES),$(FILES),$(RFC_DIR))

lint:
	@set -e; for f in $(RFC_DIR)/draft-*.md $(RFC_DIR)/[0-9]*.md; do \
		[ -e "$$f" ] && skill/rfc-lint "$$f" || true; \
	done

site:
	skill/rfc-render-site $(RFC_DIR) _site

install:
	@git diff --quiet HEAD -- skill || echo "note: skill/ is dirty — installing HEAD, not the working tree"
	@tmp=$$(mktemp -d); git archive HEAD skill | tar -x -C "$$tmp"; mkdir -p "$(SKILL_DEST)"; \
		rsync -a --delete "$$tmp/skill/" "$(SKILL_DEST)/"; rm -rf "$$tmp"; \
		echo "installed $$(git rev-parse --short HEAD) -> $(SKILL_DEST)"

digests:
	@for f in $(RFC_DIR)/draft-*.md $(RFC_DIR)/[0-9]*.md; do \
		[ -e "$$f" ] && skill/rfc-render-llm "$$f" > "$${f%.md}.llm.md.preview" || true; \
	done; echo "previews written next to sources (*.llm.md.preview — git-ignored scratch)"
