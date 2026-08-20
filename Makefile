# Conformance for this series. The gate's one body is skill/rfc-check —
# this file, CI, and the README all call it; none reimplement it.

RFC_DIR ?= rfc
SKILL_DEST ?= $(HOME)/.claude/skills/authoring-rfcs

.PHONY: check lint site digests install

# make check              -> full gate over $(RFC_DIR) (the verdict of record)
# make check FILES="..."  -> spot run over the named files (advisory)
check:
	skill/rfc-check $(if $(FILES),$(FILES),$(RFC_DIR))

lint:
	@set -e; for f in $(RFC_DIR)/draft-*.md $(RFC_DIR)/[0-9]*.md; do \
		[ -e "$$f" ] && skill/rfc-lint "$$f" || true; \
	done

site:
	skill/rfc-render-site $(RFC_DIR) _site

# make install -> install the skill into $(SKILL_DEST) from COMMITTED state.
# Deliberately `git archive HEAD`, never a copy of the working tree: when
# more than one agent works this repo, a tree copy installs whatever half
# -finished edit happens to be sitting there, from whoever touched it last.
# Installing from HEAD makes the installed copy name a commit you can point
# at. A dirty tree is reported, not silently included.
install:
	@git diff --quiet HEAD -- skill || \
		echo "note: skill/ has uncommitted changes — installing HEAD ($$(git rev-parse --short HEAD)), not the working tree"
	@tmp=$$(mktemp -d) && git archive HEAD skill | tar -x -C "$$tmp" && \
		mkdir -p "$(SKILL_DEST)" && \
		rsync -a --delete "$$tmp/skill/" "$(SKILL_DEST)/" && \
		rm -rf "$$tmp" && \
		echo "installed $$(git rev-parse --short HEAD) -> $(SKILL_DEST)"

digests:
	@for f in $(RFC_DIR)/draft-*.md $(RFC_DIR)/[0-9]*.md; do \
		[ -e "$$f" ] && skill/rfc-render-llm "$$f" > "$${f%.md}.llm.md.preview" || true; \
	done; echo "previews written next to sources (*.llm.md.preview — git-ignored scratch)"
