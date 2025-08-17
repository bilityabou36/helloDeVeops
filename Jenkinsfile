pipeline {
  agent any

  options { timestamps() }  // single options block; no extra plugins needed

  environment {
    APP_NAME   = 'false-hello'
    ECR_REPO   = 'false-hello'
    AWS_REGION = 'us-east-1'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    APP_DIR    = '.'                // change only if your code lives in a subfolder
  }

  stages {

    stage('Checkout') {
      steps { checkout scm }
    }

    // Show exactly what Jenkins has in the workspace
    stage('List workspace') {
      steps {
        sh '''
          echo "== Jenkins workspace listing =="
          pwd
          ls -la
          echo "== Search for requirements.txt and Dockerfile =="
          find . -maxdepth 2 -iname "requirements.txt" -print
          find . -maxdepth 2 -iname "dockerfile" -print
        '''
      }
    }

    stage('Lint & Tests') {
      steps {
        // Run everything inside a disposable Python container.
        // We list inside the container first, then install from ./requirements.txt explicitly.
        sh '''
          docker run --rm \
            -v "$PWD/${APP_DIR}":/src \
            -w /src python:3.11-slim /bin/bash -lc '
              set -euxo pipefail
              echo "== Inside container: /src listing ==" && pwd && ls -la
              echo "== Show first lines of requirements.txt ==" && head -n 20 ./requirements.txt
              python -m pip install --upgrade pip
              pip install --no-cache-dir -r ./requirements.txt
              # If flake8/pytest are already in requirements.txt this is enough.
              # If you want to ignore style warnings but not fail the build, keep "|| true".
              flake8 . || true
              pytest -q
            '
        '''
      }
    }

    stage('Build Docker Image') {
      steps {
        sh '''
          echo "== Building image ${APP_NAME}:${IMAGE_TAG} from ${APP_DIR} =="
          docker build -t ${APP_NAME}:${IMAGE_TAG} ${APP_DIR}
        '''
      }
    }

    stage('Trivy Scan (fail on HIGH/CRITICAL)') {
      steps {
        sh '''
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:0.50.0 image --no-progress \
            --severity HIGH,CRITICAL --exit-code 1 ${APP_NAME}:${IMAGE_TAG}
        '''
      }
    }

    stage('Login & Push to ECR') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'aws-ecr',
                  usernameVariable: 'AWS_ACCESS_KEY_ID',
                  passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
          sh '''
            set -e
            export AWS_DEFAULT_REGION=${AWS_REGION}
            ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

            # Ensure repo exists (no-op if it already exists)
            aws ecr describe-repositories --repository-names ${ECR_REPO} >/dev/null 2>&1 || \
              aws ecr create-repository --repository-name ${ECR_REPO} \
                --image-scanning-configuration scanOnPush=true

            # Docker login to ECR
            aws ecr get-login-password --region ${AWS_REGION} \
              | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

            REPO_URI=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}

            # Tag & push
            docker tag ${APP_NAME}:${IMAGE_TAG} ${REPO_URI}:${IMAGE_TAG}
            docker tag ${APP_NAME}:${IMAGE_TAG} ${REPO_URI}:latest

            docker push ${REPO_URI}:${IMAGE_TAG}
            docker push ${REPO_URI}:latest

            echo "== Pushed =="
            echo "${REPO_URI}:${IMAGE_TAG}"
            echo "${REPO_URI}:latest"
          '''
        }
      }
    }
  }

  post {
    always {
      sh 'docker image prune -f || true'
    }
  }
}



