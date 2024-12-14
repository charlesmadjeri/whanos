def languages = ['javascript', 'python', 'java', 'befunge', 'c']

languages.each { lang ->
    freeStyleJob("Whanos base images/whanos-${lang}") {
        steps {
            shell('/opt/whanos/jenkins/scripts/build_base_image.sh ' + lang)
            shell("""
                cd /images/${lang}
                docker build -t whanos-${lang}-base:latest -f Dockerfile.base .
                docker build -t whanos-${lang}:latest -f Dockerfile .
                
                # Tag images for DigitalOcean registry
                docker tag whanos-${lang}-base:latest registry.digitalocean.com/whanos-container-registry/whanos-${lang}-base:latest
                docker tag whanos-${lang}:latest registry.digitalocean.com/whanos-container-registry/whanos-${lang}:latest
            """)
            shell("""
                # Authenticate with DigitalOcean registry and push images
                echo "\$DOCKER_PASSWORD" | docker login -u "\$DOCKER_USERNAME" --password-stdin registry.digitalocean.com
                docker push registry.digitalocean.com/whanos-container-registry/whanos-${lang}-base:latest
                docker push registry.digitalocean.com/whanos-container-registry/whanos-${lang}:latest
            """)
        }
        wrappers {
            credentialsBinding {
                usernamePassword('DOCKER_USERNAME', 'DOCKER_PASSWORD', 'digitalocean-credentials')
            }
        }
    }
}

freeStyleJob('Build all base images') {
    steps {
        languages.each { lang ->
            downstreamParameterized {
                trigger("Whanos base images/whanos-${lang}") {
                    block {
                        buildStepFailure('FAILURE')
                        failure('FAILURE')
                        unstable('UNSTABLE')
                    }
                }
            }
        }
    }
} 