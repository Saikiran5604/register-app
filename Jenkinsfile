pipeline{
    agent { label 'jenkins-agent' }
    tools {
        jdk 'java21'
        maven 'Maven3'
    }

    environment {
        APP_NAME = "register-app-pipeline"
        RELEASE = "1.0.0"
        DOCKER_USER = "saikiranreddy5604"
        DOCKER_CREDENTIALS_ID = "dockerhub"
        IMAGE_NAME = "${DOCKER_USER}/${APP_NAME}"
        IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
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
                    // This matches the exact Name from your system settings screen
                    withSonarQubeEnv('sonarqube-server'){
                        sh 'mvn org.sonarsource.scanner.maven:sonar-maven-plugin:3.11.0.3922:sonar'
                    }
                }
            }
        }

        stage("Quality Gate Analysis"){
            steps {
                script {
                    // abortPipeline: true will fail the build if the code fails your quality thresholds
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
                    // Changing the first argument from '' to 'https://docker.io' is the key fix
                    docker.withRegistry('https://docker.io', "${env.DOCKER_CREDENTIALS_ID}") {
                        
                        // Builds image with the calculated tag definition
                        def docker_image = docker.build("${env.IMAGE_NAME}:${env.IMAGE_TAG}")
                        
                        // Pushes both tags explicitly using the authenticated context
                        docker_image.push()
                        docker_image.push('latest')
                    }
                }
            }
        }


    }
}
