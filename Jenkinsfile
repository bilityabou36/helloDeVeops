pipeline {
    agent any

    environment {
        IMAGE_NAME = "falsk-hello"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/bilityabou36/helloDeVeops.git'
            }
        }

        stage('Set up Python venv & Install deps') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                '''
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    . venv/bin/activate
                    flake8 --max-line-length=100
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    . venv/bin/activate
                    pytest --maxfail=1 --disable-warnings -q
                '''
            }
        }

        stage('Docker Build') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${BUILD_NUMBER} .
                '''
            }
        }

        stage('Verify deps in image') {
            steps {
                sh '''
                    echo "== Checking gunicorn version inside the container =="

                    # Show gunicorn version inside the built container
                    docker run --rm ${IMAGE_NAME}:${BUILD_NUMBER} \
                      python -c "import importlib.metadata as m; print(m.version('gunicorn'))"

                    # Fail if version < 23
                    docker run --rm ${IMAGE_NAME}:${BUILD_NUMBER} \
                      python - <<'PY'
import sys
from importlib.metadata import version
v = tuple(map(int, version("gunicorn").split(".")))
print("Detected gunicorn version:", v)
sys.exit(0 if v >= (23,0,0) else 1)
PY
                '''
            }
        }

        stage('Trivy Scan') {
            steps {
                sh '''
                    trivy image --exit-code 1 --severity HIGH,CRITICAL ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }
    }
}






