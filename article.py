from pydantic import BaseModel
from dotenv import load_dotenv
import os
from openai import OpenAI
from rich import print as rprint
from prompt_toolkit import prompt
from db import save_article, get_all_articles
from pathlib import Path

import requests
from bs4 import BeautifulSoup

home = str(Path.home())
Path(f"{home}/.config/article").mkdir(parents=True, exist_ok=True)

# check if a file exists
# if not, create it
if not os.path.exists(f"{home}/.config/article/.env"):
    with open(f"{home}/.config/article/.env", "w") as f:
        api_key = prompt("Enter your OpenAI API Key: ")
        f.write(f'OPENAI_API_KEY="{api_key}"\n')

load_dotenv(f"{home}/.config/article/.env")

OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

client = OpenAI(api_key=OPENAI_API_KEY)

class GetArticle(BaseModel):
    title: str
    classification: str
    author: str
    publish_date: str
    article_text: str

def fetch_content(url):
    headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }
    try:
        response = requests.get(url, headers= headers)
        response.raise_for_status()
        soup = BeautifulSoup(response.text, 'lxml')
        print(f"Successfully fetched content from {url}")
        return soup.get_text()
    except requests.exceptions.RequestException as e:
        raise Exception(f"Error fetching page: {e}")

def get_summary(content: str):
    completions = client.beta.chat.completions.parse(
        model = "gpt-4o-mini-2024-07-18",
        messages=[
            {"role": "system", "content": "You are an article extractor who extracts article from scraped websites. Extract the article with title, author, publish date (in ISO 8601 format) and extract the text from the article and convert it into HTML while removing all the advertisements and extra texts inside the article, also do not keep the title, author and publish date inside the article text. Also classify the article into a subcategory."},
            {"role": "user", "content": content}
        ],
        response_format=GetArticle,
    )

    generated_summary = completions.choices[0].message.parsed
    return generated_summary

if __name__ == '__main__':
    url = prompt("Enter URL: ")
    html = fetch_content(url)
    summary = get_summary(html)
    save_article(
        title= summary.title,
        classification=summary.classification,
        author=summary.author,
        publish_date=summary.publish_date,
        article_text=summary.article_text,
        article_link=url
    )
    rprint(f"Article from {summary.author} saved to database")
