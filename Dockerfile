FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    VIRTUAL_ENV=/opt/venv \
    PATH="/opt/venv/bin:$PATH"

# Create a clean virtualenv so we don't mix with any base-layer packages
RUN python -m venv "$VIRTUAL_ENV"

WORKDIR /app

# Install deps into the venv; explicitly uninstall any preexisting gunicorn just in case
COPY requirements.txt .
RUN pip install --upgrade pip \
 && pip uninstall -y gunicorn || true \
 && pip install --no-cache-dir -r requirements.txt

# Now copy only source (venv is created inside image; we don't copy any local venv)
COPY . .

# (Optional) simple health command
CMD ["gunicorn", "-b", "0.0.0.0:8000", "app:app"]


