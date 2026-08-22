pipeline {
    agent any

    environment {
        DOCKERHUB_DEV_REPO  = 'shgupta140/dev'
        DOCKERHUB_PROD_REPO = 'shgupta140/prod'
        DOCKERHUB_CREDENTIALS = credentials('DockerHubCredentials')
        AWS_REGION = 'ap-south-1'
        EC2_IP_SSM_PARAMETER = 'ReactJS_Node_Public_IP'
        EC2_SSH_USER = 'ubuntu'
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
		sh "docker push ${DOCKERHUB_PROD_REPO}:reactjs-app-${env.BUILD_NUMBER} &>> /tmp/push.log || { echo 'Docker push failed, Check push.log for details.'; exit 1;}"
            }
        }

        stage('Deploying Application') {
            when {
                expression { env.GIT_BRANCH == 'origin/main' }
            }
            steps {
                echo 'Deploying the production image to the EC2 instance...'
                sshagent(credentials: ['EC2_SSH_CREDENTIALS']) {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'DockerHubCredentials',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        )
                    ]) {
                        sh '''
                            set -eu

                            IMAGE="${DOCKERHUB_PROD_REPO}:reactjs-app-${BUILD_NUMBER}"
                            EC2_IP="$(aws ssm get-parameter \
                                --name "$EC2_IP_SSM_PARAMETER" \
                                --with-decryption \
                                --query 'Parameter.Value' \
                                --output text \
                                --region "$AWS_REGION")"
                            EC2_HOST="${EC2_SSH_USER}@${EC2_IP}"
                            echo "Deploying to ${EC2_HOST}"

                            printf '%s\n' "$DOCKER_PASS" | ssh -o StrictHostKeyChecking=no "$EC2_HOST" \
                                "docker login --username '$DOCKER_USER' --password-stdin"

                            ssh -o StrictHostKeyChecking=no "$EC2_HOST" \
                                "IMAGE='$IMAGE' bash -s" <<'REMOTE_SCRIPT'
                            set -eu
                            trap 'docker logout >/dev/null 2>&1 || true' EXIT

                            docker pull "$IMAGE"
                            docker rm -f reactjs-app 2>/dev/null || true
                            docker run -d --name reactjs-app --restart unless-stopped -p 80:80 "$IMAGE"

                            for attempt in 1 2 3 4 5 6 7 8 9 10; do
                                if curl --fail --silent --show-error http://127.0.0.1:80/ >/dev/null; then
                                    echo 'Application is running on port 80.'
                                    docker logout
                                    exit 0
                                fi
                                sleep 3
                            done

                            echo 'Application failed the port 80 health check.' >&2
                            docker logs --tail 100 reactjs-app >&2 || true
                            docker logout
                            exit 1
                            REMOTE_SCRIPT
                        '''
                    }
                }
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
