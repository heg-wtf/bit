.DEFAULT_GOAL := help
.PHONY: help build init format lint test server clean

SITE_DIR ?= docs
PORT ?= 8000
PYTHON ?= python3
RUFF ?= uvx ruff
REQUIRED_META ?= description viewport

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

build: ## Build the static site into docs/ (requires zvc on PATH)
	zvc build
	echo "bit.heg.wtf" > ./$(SITE_DIR)/CNAME

init: ## Scaffold a new post (prompts for YYMMDD)
	@read -p "Enter date (YYMMDD): " date; \
	mkdir -p ./contents/$$date; \
	year="20$${date:0:2}"; \
	month="$${date:2:2}"; \
	day="$${date:4:2}"; \
	pub_date="$$year-$$month-$$day"; \
	echo "---" > ./contents/$$date/$$date.md; \
	echo "title: '$$date'" >> ./contents/$$date/$$date.md; \
	echo "author: 'heg'" >> ./contents/$$date/$$date.md; \
	echo "pub_date: '$$pub_date'" >> ./contents/$$date/$$date.md; \
	echo "description: ''" >> ./contents/$$date/$$date.md; \
	echo "featured_image: ''" >> ./contents/$$date/$$date.md; \
	echo "tags: ['드라이버펍', 'heg']" >> ./contents/$$date/$$date.md; \
	echo "---" >> ./contents/$$date/$$date.md; \
	echo "" >> ./contents/$$date/$$date.md; \
	echo "Created ./contents/$$date/$$date.md"

format: ## Format Python helpers with ruff
	$(RUFF) format scripts tests

lint: format ## ruff check + validate built site (local assets, anchors, required meta)
	$(RUFF) check scripts tests
	$(PYTHON) scripts/check_site.py $(SITE_DIR) --require-meta $(REQUIRED_META)

test: ## Run unit tests for the site checker
	$(PYTHON) -m unittest discover -s tests -v

server: ## Serve the built site locally
	$(PYTHON) -m http.server $(PORT) --directory $(SITE_DIR)

clean: ## Remove Python caches
	find . -name "__pycache__" -type d -prune -exec rm -rf {} +
