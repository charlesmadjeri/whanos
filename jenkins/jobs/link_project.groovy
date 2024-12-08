freeStyleJob('link-project') {
    parameters {
        stringParam('GIT_URL', '', 'Git repository URL')
        stringParam('PROJECT_NAME', '', 'Name of the project')
    }

    steps {
        dsl {
            text('''
                folder('Projects')
                
                job("Projects/$PROJECT_NAME") {
                    scm {
                        git {
                            remote {
                                url('$GIT_URL')
                            }
                            branch('*/main')
                        }
                    }
                    
                    triggers {
                        scm('* * * * *')  // Check every minute
                    }
                    
                    steps {
                        // Detect language and validate project
                        shell("""
                            WORKSPACE=\$PWD
                            
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
                                exit 1
                            fi
                            
                            # Check for multiple detection criteria
                            COUNT=0
                            [ -f Makefile ] && COUNT=$((COUNT+1))
                            [ -f app/pom.xml ] && COUNT=$((COUNT+1))
                            [ -f package.json ] && COUNT=$((COUNT+1))
                            [ -f requirements.txt ] && COUNT=$((COUNT+1))
                            [ -f app/main.bf ] && COUNT=$((COUNT+1))
                            
                            if [ $COUNT -gt 1 ]; then
                                echo "Multiple language detection criteria found"
                                exit 1
                            fi
                            
                            # Build using appropriate image
                            if [ -f Dockerfile ]; then
                                # Use base image
                                docker build -t ${PROJECT_NAME}:latest --build-arg BASE_IMAGE=whanos-$LANGUAGE-base:latest .
                            else
                                # Use standalone image
                                docker build -t ${PROJECT_NAME}:latest -f /images/$LANGUAGE/Dockerfile .
                            fi
                            
                            # Deploy if K8s manifest exists
                            if [ -f manifest.yml ]; then
                                kubectl apply -f manifest.yml
                            fi
                        """)
                    }
                }
            '''.stripIndent())
        }
    }
} 