# Conformance for this series. The gate's one body is skill/rfc-check —
# this file, CI, and the README all call it; none reimplement it.

RFC_DIR ?= rfc

.PHONY: check lint site digests

check:
	skill/rfc-check $(RFC_DIR)

lint:
	@set -e; for f in $(RFC_DIR)/draft-*.md $(RFC_DIR)/[0-9]*.md; do \
		[ -e "$$f" ] && skill/rfc-lint "$$f" || true; \
	done

site:
	skill/rfc-render-site $(RFC_DIR) _site

digests:
	@for f in $(RFC_DIR)/draft-*.md $(RFC_DIR)/[0-9]*.md; do \
		[ -e "$$f" ] && skill/rfc-render-llm "$$f" > "$${f%.md}.llm.md.preview" || true; \
	done; echo "previews written next to sources (*.llm.md.preview — git-ignored scratch)"
