#!/usr/bin/env python3
import feedparser
import requests
from bs4 import BeautifulSoup
import json
from datetime import datetime
from urllib.parse import urlparse

FEEDS = [
    # Prefer Arabic-language feeds first
    'https://www.aljazeera.net/xml/rss/all.xml',
    'https://www.alarabiya.net/rss/2025/11/13/latest.xml',
    'https://feeds.bbci.co.uk/arabic/rss.xml',
    # Fallback English feeds for crypto/gold if Arabic feeds are exhausted
    'https://feeds.bbci.co.uk/news/business/rss.xml',
    'https://feeds.bbci.co.uk/news/technology/rss.xml',
    'https://www.coindesk.com/arc/outboundfeeds/rss/'
]

KEYWORDS = [
    'currency', 'currencies', 'forex', 'exchange', 'dollar', 'pound', 'euro',
    'gold', 'goldprice', 'gold price', 'bitcoin', 'crypto', 'cryptocurrency',
    'ethereum', 'btc', 'market', 'inflation'
]

def extract_image(entry):
    # Try common feed fields
    if 'media_content' in entry and entry.media_content:
        try:
            return entry.media_content[0]['url']
        except Exception:
            pass
    if 'media_thumbnail' in entry and entry.media_thumbnail:
        try:
            return entry.media_thumbnail[0]['url']
        except Exception:
            pass
    # Try enclosure
    if 'enclosures' in entry and entry.enclosures:
        try:
            return entry.enclosures[0].get('href')
        except Exception:
            pass
    # Parse summary HTML for img
    summary = entry.get('summary', '') or entry.get('content', [{}])[0].get('value', '')
    soup = BeautifulSoup(summary, 'html.parser')
    img = soup.find('img')
    if img and img.get('src'):
        return img.get('src')
    return ''

def fetch_page_image(url):
    try:
        r = requests.get(url, timeout=6, headers={'User-Agent': 'news-generator/1.0'})
        if r.status_code != 200:
            return ''
        soup = BeautifulSoup(r.text, 'html.parser')
        # OpenGraph image
        og = soup.find('meta', property='og:image')
        if og and og.get('content'):
            return og.get('content')
        # twitter:image
        tw = soup.find('meta', attrs={'name': 'twitter:image'})
        if tw and tw.get('content'):
            return tw.get('content')
        # first image in content
        img = soup.find('img')
        if img and img.get('src'):
            return img.get('src')
    except Exception:
        return ''
    return ''

def score_entry(entry):
    text = (entry.get('title', '') + ' ' + entry.get('summary', '')).lower()
    score = 0
    for k in KEYWORDS:
        if k in text:
            score += 1
    return score

def domain_from_url(url):
    try:
        p = urlparse(url)
        return p.netloc.replace('www.', '')
    except Exception:
        return 'news'

def main():
    items = []
    for feed in FEEDS:
        d = feedparser.parse(feed)
        for entry in d.entries:
            try:
                title = entry.get('title', '').strip()
                link = entry.get('link', '').strip()
                published = entry.get('published_parsed')
                ts = None
                if published:
                    ts = datetime(*published[:6]).timestamp()
                else:
                    ts = datetime.now().timestamp()
                img = extract_image(entry)
                s = score_entry(entry)
                # Validate the article URL before including it
                try:
                    head = requests.get(link, timeout=6, headers={'User-Agent': 'news-generator/1.0'})
                    if head.status_code != 200:
                        continue
                except Exception:
                    continue

                # If no image from feed, try to fetch from page
                if not img:
                    img = fetch_page_image(link)

                items.append({
                    'title': title,
                    'url': link,
                    'image': img or '',
                    'score': s,
                    'ts': ts,
                    'source': domain_from_url(link)
                })
            except Exception:
                continue

    # Prefer higher score then newer
    items.sort(key=lambda x: (-x['score'], -x['ts']))

    # If not enough scored items, pad with recent items
    if len(items) < 3:
        # re-parse feeds to append recent items
        pass

    top = []
    seen_urls = set()
    for it in items:
        if it['url'] in seen_urls:
            continue
        seen_urls.add(it['url'])
        # Ensure image is absolute and valid; if not, leave empty
        img = it.get('image') or ''
        top.append({'source': it['source'], 'title': it['title'], 'url': it['url'], 'image': img})
        if len(top) >= 3:
            break

    out = {'updated_at': datetime.utcnow().isoformat() + 'Z', 'articles': top}

    with open('api/news.json', 'w', encoding='utf-8') as f:
        json.dump(out, f, ensure_ascii=False, indent=2)

if __name__ == '__main__':
    main()