pipeline{
    agent { label 'jenkins-agent' }
    tools {
        jdk 'java21'
        maven 'Maven3'
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

    }
}
