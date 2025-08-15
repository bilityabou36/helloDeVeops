# flask-hello
Tiny Flask app to prove CI/CD.

## Build & run
```bash
docker build -t flask-hello:dev .
docker run --rm -p 5000:5000 --name flask-hello flask-hello:dev

