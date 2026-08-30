pipeline {
    agent { label 'jenkins-agent' }
    
    tools {
        jdk 'java21'
        maven 'Maven3'
    }

    environment {
        APP_NAME    = "register-app-pipeline"
        RELEASE     = "1.0.0"
        DOCKER_USER = "saikiranreddy5604"
        DOCKER_CREDENTIALS_ID = "dockerhub" 
        
        IMAGE_NAME  = "${DOCKER_USER}/${APP_NAME}"
        IMAGE_TAG   = "${RELEASE}-${BUILD_NUMBER}"
        
        // FIXED: Removed the global JENKINS_API_TOKEN declaration to avoid step block collision
    }

    stages {
        stage("Cleanup Workspace"){
            steps {
                cleanWs()
            }
        }   

        stage("Checkout from SCM"){
            steps {
                git branch: 'main', credentialsId: 'github', url: 'https://github.com/Saikiran5604/register-app'
            }
        }

        stage("Build Application"){
            steps {
                sh "mvn clean package"
            }
        }

        stage("Test Application"){
            steps {
                sh "mvn test"
            }
        }

        stage("SonarQube Analysis"){
            steps {
                script {
                    withSonarQubeEnv('sonarqube-server'){
                        sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922:sonar'
                    }
                }
            }
        }

        stage("Quality Gate Analysis"){
            steps {
                script {
                    def qg = waitForQualityGate abortPipeline: true
                    if (qg.status != 'OK') {
                        error "Pipeline aborted due to SonarQube Quality Gate failure: ${qg.status}"
                    }
                }
            }
        }

        stage("Build & Push Docker Image"){
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_CREDENTIALS_ID}", 
                                                      usernameVariable: 'DOCKER_USER_ENV', 
                                                      passwordVariable: 'DOCKER_TOKEN_ENV')]) {
                        
                        sh "echo \$DOCKER_TOKEN_ENV | docker login -u \$DOCKER_USER_ENV --password-stdin"
                        sh "docker build -t ${env.IMAGE_NAME}:${env.IMAGE_TAG} ."
                        sh "docker tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} ${env.IMAGE_NAME}:latest"
                        sh "docker push ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                        sh "docker push ${env.IMAGE_NAME}:latest"
                        sh "docker logout"
                    }
                }
            }
        }

        // FIXED: Corrected stage name spelling to match the architecture layout
        stage("Trivy Scan"){
            steps {
                sh "docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --no-progress --scanners vuln --exit-code 0 --severity HIGH,CRITICAL --format table ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
            }
        }

        stage("Cleanup Local Images"){
            steps {
                script {
                    sh "docker rmi -f ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    sh "docker rmi -f ${env.IMAGE_NAME}:latest"
                    sh "docker image prune -f"
                }
            }
        }
        
        stage("Trigger CD Pipeline") {
    steps {
        withCredentials([
            string(
                credentialsId: 'JENKINS_API_TOKEN',
                variable: 'JENKINS_API_TOKEN'
            )
        ]) {
            sh """
                curl -v -k \
                  --user "cloud-user:${JENKINS_API_TOKEN}" \
                  -X POST \
                  -H "cache-control: no-cache" \
                  -H "content-type: application/x-www-form-urlencoded" \
                  --data "IMAGE_TAG=${IMAGE_TAG}" \
                  "http://54.144.87.72:8080/job/gitops-register-app-cd/buildWithParameters"
            """
        }
    }
}



    }
}
