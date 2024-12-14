freeStyleJob('link-project') {
    parameters {
        stringParam('GIT_URL', '', 'Git repository URL (HTTPS or SSH)')
        stringParam('PROJECT_NAME', '', 'Name of the project')
        stringParam('GIT_BRANCH', 'main', 'Git branch to build (default: main)')
        credentialsParam('GIT_CREDENTIALS') {
            type('com.cloudbees.plugins.credentials.common.StandardCredentials')
            required(false)
            description('Credentials to use for private repository (username/password or SSH key)')
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
                            }
                            branch("*/${GIT_BRANCH}")
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