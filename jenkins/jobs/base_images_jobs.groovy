def languages = ['javascript', 'python', 'java', 'befunge', 'c']

languages.each { lang ->
    freeStyleJob("Whanos base images/whanos-${lang}") {
        steps {
            shell('/opt/whanos/jenkins/scripts/build_base_image.sh ' + lang)
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