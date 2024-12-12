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
                    
                    steps {
                        shell("""#!/bin/bash
                            WORKSPACE=\\\$PWD
                            
                            # Language detection
                            if [ -f Makefile ]; then
                                LANGUAGE="c"
                            elif [ -f app/pom.xml ]; then
                                LANGUAGE="java"
                            elif [ -f package.json ]; then
                                LANGUAGE="javascript"
                            elif [ -f requirements.txt ]; then
                                LANGUAGE="python"
                            elif [ -f app/main.bf ]; then
                                LANGUAGE="befunge"
                            else
                                echo "No valid Whanos project structure detected"
                                echo 'Files found: '
                                tree
                                exit 1
                            fi
                            
                            COUNT=0
                            [ -f Makefile ] && COUNT=\\\$((COUNT+1))
                            [ -f app/pom.xml ] && COUNT=\\\$((COUNT+1))
                            [ -f package.json ] && COUNT=\\\$((COUNT+1))
                            [ -f requirements.txt ] && COUNT=\\\$((COUNT+1))
                            [ -f app/main.bf ] && COUNT=\\\$((COUNT+1))
                            
                            if [ \\\$COUNT -gt 1 ]; then
                                echo "Multiple language detection criteria found"
                                exit 1
                            fi
                            
                            if [ -f Dockerfile ]; then
                                docker build -t \\\${PROJECT_NAME}:latest --build-arg BASE_IMAGE=whanos-\\\$LANGUAGE-base:latest .
                            else
                                docker build -t \\\${PROJECT_NAME}:latest -f /images/\\\$LANGUAGE/Dockerfile .
                            fi
                            # PUSH TO DOCKER REGISTRY
                            
                            if [ -f whanos.yml ]; then
                                kubectl apply -f whanos.yml
                            fi
                        """)
                    }
                }
            '''.stripIndent())
        }
    }
} 