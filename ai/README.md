source .venv/bin/activate
celery -A server_redis worker --loglevel=info --pool=solo 