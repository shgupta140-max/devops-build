pipeline {
    agent any

    environment {
        DOCKERHUB_DEV_REPO  = 'shgupta140/dev'
        DOCKERHUB_PROD_REPO = 'shgupta140/prod'
        DOCKERHUB_CREDENTIALS = credentials('DockerHubCredentials')
        SLACK_CHANNEL = '#devops-notifications'
    }

    tools {
        dockerTool 'docker'
    }

    stages {
        stage('Check Docker Version') {
            steps {
                sh 'docker --version'
            }
        }
       
        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'DockerHubCredentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                            echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }      
        }

        stage('Dev Flow: Build & Push') {
            when {
                expression { env.GIT_BRANCH == 'origin/dev' }
            }
            steps {
                echo 'Running build.sh script for dev branch'
                sh "./build.sh ${DOCKERHUB_DEV_REPO} ${env.BUILD_NUMBER}"
		echo "=============== Pushing Image to ${DOCKERHUB_DEV_REPO} ============"
		sh "docker push ${DOCKERHUB_DEV_REPO}:reactjs-app-${env.BUILD_NUMBER} &>> /tmp/push.log || { echo 'Docker push failed, Check push.log for details.'; exit 1;}"
		echo "=============== Image Pushed to repository =========="

            }
        }

        stage('Prod Flow: Build & Push') {
            when {
                expression { env.GIT_BRANCH == 'origin/main' }
            }
            steps {
                echo 'Running build.sh script for main branch'
                sh "./build.sh ${DOCKERHUB_PROD_REPO} ${env.BUILD_NUMBER}"
		echo "=============== Pushing Image to ${DOCKERHUB_PROD_REPO} ============"
		sh "docker push ${DOCKERHUB_PROD_REPO}:$reactjs-app-${env.BUILD_NUMBER} &>> /tmp/push.log || { echo 'Docker push failed, Check push.log for details.'; exit 1;}"
            }
        }

        stage('Deploying Application') {
	    when {
                expression { env.GIT_BRANCH == 'origin/main' }
            }
            steps {
                echo 'Running deploy.sh for Production environment...'
                sh "./deploy.sh ${DOCKERHUB_PROD_REPO} ${env.BUILD_NUMBER} 80"
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
            script {
                def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(
                    script: 'git rev-parse --abbrev-ref HEAD',
                    returnStdout: true
                ).trim()

                echo 'Build and deployment succeeded!'
                slackSend(channel: SLACK_CHANNEL, color: 'good', message: "Build #${env.BUILD_NUMBER} succeeded for branch ${branchName}.")
            }
        }
        failure {
            script {
                def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: sh(
                    script: 'git rev-parse --abbrev-ref HEAD',
                    returnStdout: true
                ).trim()

                echo 'Build or deployment failed!'
                slackSend(channel: SLACK_CHANNEL, color: 'danger', message: "Build #${env.BUILD_NUMBER} failed for branch ${branchName}.")
            }
        }
    }
}
