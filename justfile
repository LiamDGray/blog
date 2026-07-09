serve:
	hugo server -D --bind 0.0.0.0

build:
	hugo

deploy:
	npx wrangler pages deploy

# Usage: just new-post "My New Post Title"
new-post post_title="":
	@if [ -z "{{post_title}}" ]; then echo "Usage: just new-post \"My Post Title\""; exit 1; fi
	@slug="$(echo "{{post_title}}" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$$//')"; \
	hugo new content "content/blog/$$slug.md"
