# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**bit** is a minimalist "building-in-public" microblog published at `bit.heg.wtf`. It's a static site built with Python and deployed to GitHub Pages via the `docs/` folder.

## Tech Stack

- **Python 3.12+** with `uv` package manager
- **zvc** (`0.1.6`) - static site generator (Jinja2 + Markdown + YAML)
- **GitHub Pages** - deployment target (serves from `docs/`)
- **Outfit** (Google Fonts) for UI/headings, system Korean sans-serif for body, **BitcountSingle** for the `bit` wordmark
- Design tokens mirror heg.wtf (Tailwind gray + blue `#3b82f6`, light/dark via `prefers-color-scheme`); see `themes/bit/assets/style.css`

## Build & Development Commands

```bash
# Build the static site (outputs to docs/, creates CNAME)
make build

# Create a new blog post scaffold (prompts for YYMMDD date)
make init

# Validate the built site (ruff + local asset/anchor/meta checks on docs/)
make lint

# Unit tests for scripts/check_site.py
make test

# Serve docs/ locally on http://localhost:8000
make server
```

`make build` expects `zvc` on PATH (activate `.venv` or run `PATH=.venv/bin:$PATH make build`). `make lint` runs after a build and validates every HTML file under `docs/`.

## Architecture

### Content Pipeline

`contents/{YYMMDD}/{YYMMDD}.md` → `zvc build` → `docs/` (static HTML)

1. **Source**: Markdown files with YAML frontmatter in `contents/` (folders named by date YYMMDD)
2. **Templates**: Jinja2 templates in `themes/bit/` — `index.html` (homepage timeline) and `post.html` (individual post)
3. **Styling**: `themes/bit/assets/style.css` — bento tiles, same tokens as heg.wtf; home lists post cards (latest as feature), each post has its own page
4. **Output**: `docs/` folder with structure `docs/YYYY/MM/DD/{slug}/index.html`

### Key Configuration

- `config.yaml` — theme name, blog title/description, output path
- `pyproject.toml` — Python dependencies (only `zvc`)
- `docs/CNAME` — custom domain `bit.heg.wtf` (regenerated on each build)

### Post Frontmatter Format

```yaml
---
title: 'YYMMDD'
author: 'heg'
pub_date: 'YYYY-MM-DD'
description: ''
featured_image: ''
tags: ['드라이버펍', 'heg']
---
```

## Conventions

- Blog content is written in **Korean**
- Commit messages follow **gitmoji** style (see parent org CLAUDE.md at `../.claude/CLAUDE.md`)
- Direct commits to `main` branch unless PR is explicitly requested
