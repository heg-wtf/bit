# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**bit** is a minimalist "building-in-public" microblog published at `bit.heg.wtf`. It's a static site built with Python and deployed to GitHub Pages via the `docs/` folder.

## Tech Stack

- **Python 3.12+** with `uv` package manager
- **zvc** (`0.1.6`) - static site generator (Jinja2 + Markdown + YAML)
- **GitHub Pages** - deployment target (serves from `docs/`)
- **Pretendard** font for body, **BitcountSingle** for headings

## Build & Development Commands

```bash
# Build the static site (outputs to docs/, creates CNAME)
make build

# Create a new blog post scaffold (prompts for YYMMDD date)
make init
```

There is no test suite, linter config, or dev server in this project. Preview locally by opening `docs/index.html` or using VS Code Live Preview.

## Architecture

### Content Pipeline

`contents/{YYMMDD}/{YYMMDD}.md` → `zvc build` → `docs/` (static HTML)

1. **Source**: Markdown files with YAML frontmatter in `contents/` (folders named by date YYMMDD)
2. **Templates**: Jinja2 templates in `themes/bit/` — `index.html` (homepage timeline) and `post.html` (individual post)
3. **Styling**: `themes/bit/assets/style.css` — monospace-first, minimalist aesthetic
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
