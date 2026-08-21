pipeline {
    agent any

    environment {
        DOCKERHUB_DEV_REPO  = 'shgupta140/dev'
        DOCKERHUB_PROD_REPO = 'shgupta140/prod'
        DOCKERHUB_CREDENTIALS = credentials('DockerHubCredentials')
        SLACK_CHANNEL = '#devops-notifications'
    }

    tools {
        docker 'docker'
    }

    stages {
        stage('Check Docker Version') {
            steps {
                sh 'docker --version'
            }
            
        stage('Docker Login') {
            steps {
                script {
                    docker.login(credentialsId: "${DOCKERHUB_CREDENTIALS}")
                }
            }
        }

        stage('Dev Flow: Build & Push') {
            when {
                branch 'dev'
            }
            steps {
                echo 'Running build.sh script for dev branch'
                sh "./build.sh ${DOCKERHUB_DEV_REPO} dev-${env.BUILD_NUMBER}"
            }
        }

        stage('Prod Flow: Build & Push') {
            when {
                branch 'main'
            }
            steps {
                echo 'Running build.sh script for main branch'
                sh "./build.sh ${DOCKERHUB_PROD_REPO} prod-${env.BUILD_NUMBER}"
            }
        }

        stage('Deploying Application') {
            when {
                branch 'main'
            }
            steps {
                echo 'Running deploy.sh for Production environment...'
                sh "./deploy.sh ${DOCKERHUB_PROD_REPO} prod-${env.BUILD_NUMBER} 80"
            }
        }
    }

    post {
        always {
            echo 'Cleaning up workspace...'
            cleanWs()
            sh "docker logout"
        }
        success {
            echo 'Build and deployment succeeded!'
            slackSend(channel: SLACK_CHANNEL, color: 'good', message: "Build #${env.BUILD_NUMBER} succeeded for branch ${env.BRANCH_NAME}.")
        }
        failure {
            echo 'Build or deployment failed!'
            slackSend(channel: SLACK_CHANNEL, color: 'danger', message: "Build #${env.BUILD_NUMBER} failed for branch ${env.BRANCH_NAME}.")
        }
    }
}
