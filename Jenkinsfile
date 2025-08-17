pipeline {
  agent any

  environment {
    APP_NAME   = 'false-hello'           // image name before pushing
    ECR_REPO   = 'false-hello'           // must match your ECR repo name in ECR
    AWS_REGION = 'us-east-1'             // set your region
    IMAGE_TAG  = "${env.BUILD_NUMBER}"   // unique tag per build
  }

  options { timestamps(); ansiColor('xterm') }

  stages {
    stage('Checkout') {
      steps {
        // If your GitHub repo is private, configure "Pipeline from SCM" in the job
        // and provide Git credentials there. For a public repo, this works:
        checkout scm
      }
    }

    stage('Lint & Tests') {
      steps {
        // Run lint/tests in a disposable Python container
        sh '''
          docker run --rm -v "$PWD":/src -w /src python:3.11-slim /bin/bash -lc "
            pip install --no-cache-dir -r requirements.txt &&
            pip install --no-cache-dir flake8 pytest &&
            flake8 . &&
            pytest -q
          "
        '''
      }
    }

    stage('Build Docker Image') {
      steps { sh 'docker build -t ${APP_NAME}:${IMAGE_TAG} .' }
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

            echo "Pushed ${REPO_URI}:${IMAGE_TAG} and :latest"
          '''
        }
      }
    }
  }

  post {
    always { sh 'docker image prune -f || true' }
  }

  options { timestamps() }

}

