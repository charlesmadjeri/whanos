def languages = ['javascript', 'python', 'java', 'befunge', 'c']

languages.each { lang ->
    freeStyleJob("Whanos base images/whanos-${lang}") {
        steps {
            shell("""
                cd /images/${lang}
                docker build -t whanos-${lang}-base:latest -f Dockerfile.base .
                docker build -t whanos-${lang}:latest -f Dockerfile .
            """)
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