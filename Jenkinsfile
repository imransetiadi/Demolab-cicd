pipeline {
  agent any
  tools {

  maven 'maven'

  }
    stages {

      stage ('Checkout SCM - BitBucket'){
        steps {
          checkout([$class: 'GitSCM', branches: [[name: '*/master']], doGenerateSubmoduleConfigurations: false, extensions: [], submoduleCfg: [], userRemoteConfigs: [[credentialsId: 'git', url: 'https://imransetiadi@bitbucket.org/imransetiadi/devops-pipeline-project.git']]])
        }
      }

          stage ('Build')  {
              steps {

            dir('java-source'){
            sh "mvn package"
          }
        }

      }

     stage ('SonarQube Analysis') {
        steps {
              withSonarQubeEnv('sonar') {

                                dir('java-source'){
                 sh '/opt/apache-maven-3.6.3/bin/mvn -U clean install sonar:sonar -Dsonar.projectKey=imran -Dsonar.host.url=http://10.8.60.239:9000 -Dsonar.login=sqp_2df9f248f1486a5f32b24adc556a8d994d37970e'
                }
              }
            }
      }


    stage('Copy Dockerfile & Playbook to Ansible Server') {

            steps {
                  sshagent(['sshkey']) {

                        sh "scp -o StrictHostKeyChecking=no Dockerfile imran@10.8.60.227:/home/imran"
                        sh "scp -o StrictHostKeyChecking=no create-container-image.yaml imran@10.8.60.227:/home/imran"
                    }

                }

        }

    stage('Build Container Image with Ansible') {

            steps {
                  sshagent(['sshkey']) {

                        sh "ssh -o StrictHostKeyChecking=no imran@10.8.60.227 -C \"sudo ansible-playbook create-container-image.yaml\""

                    }

                }

        }

    stage('Copy Deployment & Service to K8s') {

            steps {
                  sshagent(['sshkey']) {

                        sh "scp -o StrictHostKeyChecking=no create-k8s-deployment.yaml imran@10.8.60.201:/home/imran"
                        sh "scp -o StrictHostKeyChecking=no nodePort.yaml imran@10.8.60.201:/home/imran"
                    }
                }

        }

    stage('Waiting for Approvals') {

        steps{

                                input('Test Completed ? Please provide  Approvals for Prod Release ?')
                          }

    }
    
    stage('Deploy Application to K8s') {

            steps {
                  sshagent(['sshkey']) {

                        sh "ssh -o StrictHostKeyChecking=no imran@10.8.60.201 -C \"sudo kubectl apply -f create-k8s-deployment.yaml\""
                        sh "ssh -o StrictHostKeyChecking=no imran@10.8.60.201 -C \"sudo kubectl apply -f nodePort.yaml\""
                    }
                }

        }

   }
}

