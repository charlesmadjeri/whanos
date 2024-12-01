def languages = ['nodejs', 'python', 'java', 'befunge', 'c']

languages.each { lang ->
    freeStyleJob("whanos-${lang}") {
        disabled(false)
        // steps {
        //     shell("echo 'TODO: Build whanos-${lang} base image'")
        // }
    }
}

freeStyleJob('Build all base images') {
    disabled(false)
    // steps {
    //     shell("echo 'TODO: Build all base images'")
    // }
} 