from peewee import *

db = SqliteDatabase('storage.db', pragmas={
    'journal_mode': 'wal',
    'cache_size': -1024 * 64})

class Article(Model):
    title = CharField()
    classification = CharField()
    author = CharField()
    publish_date = DateField()
    article_text = TextField()
    article_link = CharField()

    class Meta:
        database = db

def initialize_db():
    db.connect()
    db.create_tables([Article], safe=True)
    db.close()

def save_article(title, classification, author, publish_date, article_text, article_link):
    db.connect()
    article = Article(
        title = title,
        classification = classification,
        author = author,
        publish_date = publish_date,
        article_text = article_text,
        article_link = article_link
    )
    article.save()
    db.close()
    print("Saved to Database")

def get_all_articles() -> list[Article]:
    db.connect()
    articles = list(Article.select())
    db.close()
    return articles

initialize_db()


