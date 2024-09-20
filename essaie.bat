^l
from flask import Flask, request, redirect, render_template
import string
import random
import sqlite3

app = Flask(__name__)

# Générateur d'URL unique
def generate_short_id(num_of_chars):
    return ''.join(random.choices(string.ascii_letters + string.digits, k=num_of_chars))

# Fonction pour se connecter à la base de données SQLite
def init_db():
    with sqlite3.connect("database.db") as conn:
        conn.execute("""
        CREATE TABLE IF NOT EXISTS urls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            short_id TEXT NOT NULL UNIQUE,
            original_url TEXT NOT NULL
        )
        """)

# Route pour afficher le formulaire d'accueil
@app.route('/', methods=['GET', 'POST'])
def index():
    if request.method == 'POST':
        original_url = request.form['original_url']
        short_id = generate_short_id(6)

        with sqlite3.connect("database.db") as conn:
            conn.execute("INSERT INTO urls (short_id, original_url) VALUES (?, ?)", (short_id, original_url))
        
        short_url = request.host_url + short_id
        return render_template('index.html', short_url=short_url)

    return render_template('index.html')

# Rediriger vers l'URL d'origine en utilisant l'ID court
@app.route('/<short_id>')
def redirect_to_url(short_id):
    with sqlite3.connect("database.db") as conn:
        cursor = conn.execute("SELECT original_url FROM urls WHERE short_id = ?", (short_id,))
        row = cursor.fetchone()
        if row:
            return redirect(row[0])
        else:
            return "URL non trouvée", 404

# Lancer l'application
if __name__ == '__main__':
    init_db()
    app.run(debug=True)

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Raccourcisseur d'URL</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha1/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body>
    <div class="container mt-5">
        <h1 class="text-center">Raccourcisseur d'URL</h1>
        <form method="POST" action="/">
            <div class="form-group">
                <label for="original_url">Entrez votre URL:</label>
                <input type="url" class="form-control" id="original_url" name="original_url" placeholder="https://exemple.com" required>
            </div>
            <button type="submit" class="btn btn-primary mt-3">Raccourcir</button>
        </form>

        {% if short_url %}
        <div class="alert alert-success mt-4">
            Votre URL raccourcie : <a href="{{ short_url }}">{{ short_url }}</a>
        </div>
        {% endif %}
    </div>
</body>
</html>
