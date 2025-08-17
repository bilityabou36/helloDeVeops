pipeline {
  agent any
  options { timestamps() }

  environment {
    APP_NAME   = 'false-hello'
    ECR_REPO   = 'false-hello'
    AWS_REGION = 'us-east-1'
    IMAGE_TAG  = "${env.BUILD_NUMBER}"
    // Jenkins job/workspace names
    JENKINS_VOL = 'jenkins_home'                   // <— the Docker volume you created
    JOB_DIR     = "/var/jenkins_home/workspace/${JOB_NAME}"
  }

  stages {
    stage('Checkout') { steps { checkout scm } }

    stage('List workspace') {
      steps {
        sh '''
          echo "== Jenkins container workspace =="
          pwd; ls -la
          echo "== Should see requirements.txt and Dockerfile above =="
        '''
      }
    }

    stage('Lint & Tests (in Python container w/ jenkins_home volume)') {
      steps {
        sh '''
          docker run --rm \
            -v ${JENKINS_VOL}:/var/jenkins_home \
            -w "${JOB_DIR}" \
            python:3.11-slim /bin/bash -lc '
              set -euxo pipefail
              echo "== Inside python container, listing JOB_DIR =="
              pwd; ls -la
              echo "== requirements.txt head =="
              head -n 20 requirements.txt
              python -m pip install --upgrade pip
              pip install --no-cache-dir -r requirements.txt
              # if you want strict linting, remove "|| true"
              pip install --no-cache-dir flake8 pytest
              flake8 app.py || true
              pytest -q
            '
        '''
      }
    }

    stage('Build Docker Image (stream workspace tar to docker)') {
      steps {
        sh '''
          echo "== Tar the workspace and stream as build context =="
          tar -C "${WORKSPACE}" -cf - . | \
            docker build -t ${APP_NAME}:${IMAGE_TAG} -f Dockerfile -
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

            aws ecr describe-repositories --repository-names ${ECR_REPO} >/dev/null 2>&1 || \
              aws ecr create-repository --repository-name ${ECR_REPO} \
                --image-scanning-configuration scanOnPush=true

            aws ecr get-login-password --region ${AWS_REGION} \
              | docker login --username AWS --password-stdin ${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

            REPO_URI=${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${ECR_REPO}
            docker tag ${APP_NAME}:${IMAGE_TAG} ${REPO_URI}:${IMAGE_TAG}
            docker tag ${APP_NAME}:${IMAGE_TAG} ${REPO_URI}:latest
            docker push ${REPO_URI}:${IMAGE_TAG}
            docker push ${REPO_URI}:latest
            echo "Pushed:"
            echo " - ${REPO_URI}:${IMAGE_TAG}"
            echo " - ${REPO_URI}:latest"
          '''
        }
      }
    }
  }

  post {
    always { sh 'docker image prune -f || true' }
  }
}




