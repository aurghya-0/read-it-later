from pydantic import BaseModel
from dotenv import load_dotenv
import os
from openai import OpenAI
from rich import print as rprint
from prompt_toolkit import prompt
from db import save_article, get_all_articles

import requests
from bs4 import BeautifulSoup

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

client = OpenAI(api_key=OPENAI_API_KEY)

class GetArticle(BaseModel):
    title: str
    classification: str
    author: str
    publish_date: str
    article_text: str

def save_article_as_markdown(article,url):
    # Base directory where markdown files will be saved
    base_directory = "/Users/aurghyadip/articles"
    
    # Create a subdirectory for the classification
    classification_directory = os.path.join(base_directory, article.classification)

    final_directory = os.path.join(classification_directory, article.publish_date)
    
    # Create the classification directory if it doesn't exist
    if not os.path.exists(final_directory):
        os.makedirs(final_directory)
    
    # Create a valid filename from the title (remove or replace invalid characters)
    filename = f"{article.title.replace('/', '_')}.md"
    
    # Full path where the markdown file will be saved
    filepath = os.path.join(final_directory, filename)
    
    # Prepare the markdown content
    markdown_content = f"{article.article_text}\n\n\n" \
                       "---\n" \
                       f"Original Article Link - [Original Article]({url})\n"
    
    # Save the content into a markdown file
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(markdown_content)

    print(f"Markdown file '{filename}' created successfully in '{final_directory}'.")

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
            {"role": "system", "content": "You are an article extractor who extracts article from scraped websites. Extract the article with title, author, publish date (in ISO 8601 format) and extract the text from the article and convert it into plaintext while removing all the advertisements and extra texts inside the article. Also classify the article into a subcategory."},
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
    result = get_all_articles()
    categories = [r.classification for r in result]
    rprint(categories)
    # save_article_as_markdown(summary, url)
    # rprint(f"Title = {summary.title}")
    # rprint(f"Author = {summary.author}")
    # rprint(f"Date = {summary.publish_date}")
    # rprint(f"Tag = {summary.classification}")
    # rprint(f"{summary.article_text}")
   

    