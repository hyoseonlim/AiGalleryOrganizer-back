FROM python:3.11-slim

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy dependency files and install dependencies first
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-cache

# Copy the entrypoint script and make it executable
COPY entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

# Copy the rest of the application code
COPY . .

EXPOSE 8000

ENTRYPOINT ["./entrypoint.sh"]
CMD ["uv", "run", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
