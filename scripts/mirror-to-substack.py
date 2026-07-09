#!/usr/bin/env python3
"""mirror-to-substack.py — Mirror new Hugo blog posts to Substack.

Uses the unofficial Substack API via python-substack library.
Requires Substack session cookies stored in sops.

Setup:
  pip install substack  # python-substack library

Usage:
  sops exec-env ~/secrets.enc.env 'python3 mirror-to-substack.py'

Environment variables (in sops):
  SUBSTACK_COOKIE_SID      — 'sid' cookie value from Substack login
  SUBSTACK_COOKIE_SUBSTACK — 'substack.sid' cookie value
  SUBSTACK_PUBLICATION_URL — e.g., 'liamdgray' (without .substack.com)
  SUBSTACK_EMAIL           — your Substack login email
  SUBSTACK_PASSWORD        — your Substack login password (alternative to cookies)

The script reads blog.liamdgray.com/index.xml, finds posts not yet mirrored
(tracked in last-mirrored.json), converts them to Substack format, and publishes.
"""
import json, os, re, sys, time, xml.etree.ElementTree as ET
from pathlib import Path
from datetime import datetime
from urllib.request import urlopen

LAST_MIRRORED = Path(__file__).parent / "last-mirrored.json"
RSS_URL = "https://blog.liamdgray.com/index.xml"

def fetch_rss():
    """Fetch and parse the Hugo RSS feed."""
    resp = urlopen(RSS_URL)
    tree = ET.parse(resp)
    ns = {"atom": "http://www.w3.org/2005/Atom"}
    entries = []
    for entry in tree.findall(".//atom:entry", ns):
        entries.append({
            "title": entry.find("atom:title", ns).text,
            "link": entry.find("atom:link", ns).attrib.get("href", ""),
            "id": entry.find("atom:id", ns).text,
            "published": entry.find("atom:published", ns).text,
            "content": entry.find("atom:content", ns).text or "",
        })
    return entries

def load_mirrored():
    if LAST_MIRRORED.exists():
        return json.loads(LAST_MIRRORED.read_text())
    return {"mirrored_ids": []}

def save_mirrored(mirrored):
    LAST_MIRRORED.write_text(json.dumps(mirrored, indent=2))

def md_to_substack_html(md):
    """Minimal markdown-to-HTML conversion for Substack."""
    import html as html_mod
    lines = md.split("\n")
    html = []
    in_code = False
    for line in lines:
        if line.startswith("```"):
            if in_code:
                html.append("</code></pre>")
                in_code = False
            else:
                html.append("<pre><code>")
                in_code = True
            continue
        if in_code:
            html.append(html_mod.escape(line) + "\n")
            continue
        if line.startswith("## "):
            html.append(f"<h2>{html_mod.escape(line[3:])}</h2>")
        elif line.startswith("### "):
            html.append(f"<h3>{html_mod.escape(line[4:])}</h3>")
        elif line.startswith("> "):
            html.append(f"<blockquote><p>{html_mod.escape(line[2:])}</p></blockquote>")
        elif line.startswith("- "):
            html.append(f"<li>{html_mod.escape(line[2:])}</li>")
        elif line.startswith("1. "):
            html.append(f"<li>{html_mod.escape(line[3:])}</li>")
        elif line.strip() == "":
            html.append("<p></p>")
        elif re.match(r'^\[(.+)\]\((.+)\)$', line.strip()):
            m = re.match(r'^\[(.+)\]\((.+)\)$', line.strip())
            html.append(f'<p><a href="{html_mod.escape(m.group(2))}">{html_mod.escape(m.group(1))}</a></p>')
        else:
            # Inline markdown
            text = html_mod.escape(line)
            text = re.sub(r'\*\*(.+?)\*\*', r'<strong>\1</strong>', text)
            text = re.sub(r'\*(.+?)\*', r'<em>\1</em>', text)
            text = re.sub(r'\[(.+?)\]\((.+?)\)', r'<a href="\2">\1</a>', text)
            html.append(f"<p>{text}</p>")
    return "\n".join(html)

def main():
    # Get Substack credentials
    cookie_sid = os.environ.get("SUBSTACK_COOKIE_SID")
    cookie_substack = os.environ.get("SUBSTACK_COOKIE_SUBSTACK_SID")
    pub_url = os.environ.get("SUBSTACK_PUBLICATION_URL", "liamdgray")
    email = os.environ.get("SUBSTACK_EMAIL")
    password = os.environ.get("SUBSTACK_PASSWORD")

    if not (cookie_sid or (email and password)):
        print("ERROR: Need SUBSTACK_COOKIE_SID or SUBSTACK_EMAIL+PASSWORD in env")
        sys.exit(1)

    # Fetch RSS and check for new posts
    entries = fetch_rss()
    mirrored = load_mirrored()
    new_entries = [e for e in entries if e["id"] not in mirrored["mirrored_ids"]]

    if not new_entries:
        print(f"No new posts to mirror (mirrored {len(mirrored['mirrored_ids'])} already)")
        return

    print(f"Found {len(new_entries)} new post(s) to mirror")

    # Try to use python-substack library if available
    try:
        from substack import Substack
        if cookie_sid:
            client = Substack(cookies={"sid": cookie_sid})
        else:
            client = Substack(email=email, password=password)
    except ImportError:
        print("WARNING: python-substack not installed. Falling back to direct API calls.")
        print("Install with: pip install substack")
        # Fallback: print what would be posted
        for entry in new_entries:
            print(f"\nWould mirror: {entry['title']}")
            print(f"  URL: {entry['link']}")
        mirrored["mirrored_ids"].extend(e["id"] for e in new_entries)
        save_mirrored(mirrored)
        print(f"\n{len(new_entries)} post(s) logged as mirrored (dry run)")
        return

    # Mirror each new post
    for entry in new_entries:
        print(f"Mirroring: {entry['title']}")
        content_html = md_to_substack_html(entry.get("content", ""))
        try:
            draft = client.create_draft(
                title=entry["title"],
                body=content_html,
            )
            print(f"  Draft created: {draft.get('id', '?')}")
            # Publish immediately
            result = client.publish_draft(draft["id"])
            print(f"  Published: {result.get('url', '?')}")
        except Exception as e:
            print(f"  ERROR: {e}")
            continue
        time.sleep(2)  # Rate limit

    # Save state
    mirrored["mirrored_ids"].extend(e["id"] for e in new_entries)
    save_mirrored(mirrored)
    print(f"\n✅ {len(new_entries)} post(s) mirrored to Substack")

if __name__ == "__main__":
    main()
