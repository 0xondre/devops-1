import os

import psycopg2
from psycopg2.extras import RealDictCursor
from flask import Flask, jsonify, request

app = Flask(__name__)


def get_conn():
    return psycopg2.connect(
        host=os.environ.get("DB_HOST", "localhost"),
        port=os.environ.get("DB_PORT", "5432"),
        dbname=os.environ.get("DB_NAME", "notes_db"),
        user=os.environ.get("DB_USER", "notes_user"),
        password=os.environ.get("DB_PASSWORD", ""),
        connect_timeout=5,
    )


@app.get("/api/health")
def health():
    """Sprawdza backend ORAZ połączenie z bazą - przydatne do testowania sieci/firewalla."""
    try:
        conn = get_conn()
        try:
            with conn.cursor() as cur:
                cur.execute("SELECT 1")
        finally:
            conn.close()
        return jsonify(status="ok", database="up")
    except Exception as e:
        return jsonify(status="error", database="down", detail=str(e)), 503


@app.get("/api/notes")
def list_notes():
    conn = get_conn()
    try:
        with conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute("SELECT id, content, created_at FROM notes ORDER BY id DESC")
            return jsonify(cur.fetchall())
    finally:
        conn.close()


@app.post("/api/notes")
def add_note():
    data = request.get_json(silent=True) or {}
    content = (data.get("content") or "").strip()
    if not content:
        return jsonify(error="content is required"), 400
    conn = get_conn()
    try:
        with conn, conn.cursor(cursor_factory=RealDictCursor) as cur:
            cur.execute(
                "INSERT INTO notes (content) VALUES (%s) RETURNING id, content, created_at",
                (content,),
            )
            return jsonify(cur.fetchone()), 201
    finally:
        conn.close()


@app.delete("/api/notes/<int:note_id>")
def delete_note(note_id):
    conn = get_conn()
    try:
        with conn, conn.cursor() as cur:
            cur.execute("DELETE FROM notes WHERE id = %s", (note_id,))
            if cur.rowcount == 0:
                return jsonify(error="not found"), 404
        return "", 204
    finally:
        conn.close()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)
