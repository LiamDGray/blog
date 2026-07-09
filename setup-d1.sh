#!/usr/bin/env bash
# setup-d1.sh — Create D1 database + table for blog email subscriptions
# Run once: bash setup-d1.sh
set -euo pipefail

echo "Creating D1 database 'blog-subscribers'..."
npx wrangler d1 create blog-subscribers --name blog-subscribers 2>&1 || true

echo ""
echo "=== D1 binding to add to wrangler.toml ==="
echo "[[d1_databases]]"
echo 'binding = "DB"'
echo 'database_name = "blog-subscribers"'
echo 'database_id = "<get-id-from-above>"'
echo ""
echo "=== SQL to initialize the table ==="
echo "Run: npx wrangler d1 execute blog-subscribers --command='CREATE TABLE IF NOT EXISTS subscribers (email TEXT PRIMARY KEY, created_at TEXT NOT NULL);'"
echo ""
echo "=== Deploy with D1 binding ==="
echo "npx wrangler pages deploy public --project-name blog --binding DB=<db-id>"
