freeStyleJob('link-project') {
    parameters {
        stringParam('GIT_URL', '', 'Git repository URL (HTTPS or SSH)')
        stringParam('PROJECT_NAME', '', 'Name of the project')
        stringParam('GIT_BRANCH', 'main', 'Git branch to build (default: main)')
        credentialsParam('GIT_CREDENTIALS') {
            type('com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl')
            required(false)
            defaultValue('')
            description('Credentials to use for private repository (username/password)')
        }
        credentialsParam('GIT_SSH_KEY') {
            type('com.cloudbees.jenkins.plugins.sshcredentials.impl.BasicSSHUserPrivateKey')
            required(false)
            defaultValue('')
            description('SSH key to use for private repository')
        }
    }

    steps {
        dsl {
            text('''
                job("Projects/$PROJECT_NAME") {
                    scm {
                        git {
                            remote {
                                url("${GIT_URL}")
                                if (GIT_CREDENTIALS) {
                                    credentials(GIT_CREDENTIALS)
                                }
                                if (GIT_SSH_KEY) {
                                    credentials(GIT_SSH_KEY)
                                }
                            }
                            branch("*/${GIT_BRANCH}")
                            extensions {
                                cloneOptions {
                                    timeout(10)
                                }
                            }
                        }
                    }
                    
                    triggers {
                        scm('* * * * *')
                    }
                    
                    wrappers {
                        credentialsBinding {
                            string('REGISTRY_TOKEN', 'do-registry-token')
                            string('REGISTRY_USERNAME', 'do-registry-username')
                        }
                    }
                    
                    steps {
                        shell('/opt/whanos/jenkins/scripts/build_project.sh')
                    }
                }
            '''.stripIndent())
        }
    }
} 