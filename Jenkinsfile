pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    IMAGE_NAME = 'false-hello'
    TRIVY_VER  = '0.50.0'
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
      }
    }

    stage('List workspace') {
      steps {
        sh '''
          echo "== Jenkins container workspace =="
          pwd
          ls -la
          echo "== Should see requirements.txt and Dockerfile above =="
        '''
      }
    }

    stage('Lint & Tests (in Python container w/ jenkins_home volume)') {
      steps {
        sh '''
          docker run --rm \
            -v jenkins_home:/var/jenkins_home \
            -w "$WORKSPACE" \
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
              PYTHONPATH=. pytest -q
            '
        '''
      }
    }

    stage('Build Docker Image (stream workspace tar to docker)') {
      steps {
        sh '''
          echo "== Tar the workspace and stream as build context =="
          # ensure a fresh build (no cached layers)
          docker builder prune -af || true
          tar -C "$WORKSPACE" -cf - . | \
            docker build --no-cache -t ${IMAGE_NAME}:${BUILD_NUMBER} -f Dockerfile -
        '''
      }
    }

    stage('Trivy Scan (fail on HIGH/CRITICAL)') {
      steps {
        sh '''
          docker run --rm \
            -v /var/run/docker.sock:/var/run/docker.sock \
            aquasec/trivy:${TRIVY_VER} image \
              --no-progress \
              --severity HIGH,CRITICAL \
              --exit-code 1 \
              ${IMAGE_NAME}:${BUILD_NUMBER}
        '''
      }
    }

    stage('Login & Push to ECR') {
      when { expression { return false } } // flip to true when you’re ready
      steps {
        echo 'Add your ECR login + push here when ready.'
      }
    }
  }

  post {
    always {
      sh 'docker image prune -f || true'
    }
  }
}





