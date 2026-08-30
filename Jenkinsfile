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
                    // Wires your 'dockerhub' credentials safely into temporary env tokens
                    withCredentials([usernamePassword(credentialsId: "${env.DOCKER_CREDENTIALS_ID}", 
                                                      usernameVariable: 'DOCKER_USER_ENV', 
                                                      passwordVariable: 'DOCKER_TOKEN_ENV')]) {
                        
                        // 1. Authenticate the host daemon explicitly via standard shell
                        sh "echo \$DOCKER_TOKEN_ENV | docker login -u \$DOCKER_USER_ENV --password-stdin"
                        
                        // 2. Build the image locally
                        sh "docker build -t ${env.IMAGE_NAME}:${env.IMAGE_TAG} ."
                        
                        // 3. Tag the image alias for 'latest'
                        sh "docker tag ${env.IMAGE_NAME}:${env.IMAGE_TAG} ${env.IMAGE_NAME}:latest"
                        
                        // 4. Push both tags cleanly via the authenticated shell session
                        sh "docker push ${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                        sh "docker push ${env.IMAGE_NAME}:latest"
                        
                        // 5. Clean up authentication footprint from the agent
                        sh "docker logout"
                    }
                }
            }
        }
    
    }
}
