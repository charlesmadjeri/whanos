freeStyleJob('link-project') {
    disabled(false)
    parameters {
        stringParam('GIT_URL', '', 'Git repository URL')
        stringParam('PROJECT_NAME', '', 'Name of the project')
        choiceParam('LANGUAGE', ['nodejs', 'python', 'java', 'befunge', 'c'], 'Project language')
    }
    // steps {
    //     shell("echo 'TODO: Link project ${PROJECT_NAME} (${LANGUAGE}) from ${GIT_URL}'")
    // }
} 