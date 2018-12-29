freeStyleJob('maintenance_cleanup') {
    displayName('cleanup')
    description('Purge all of the Docker cache.')

    weight(6)

    checkoutRetryCount(3)

    properties {
        githubProjectUrl('https://github.com/jessfraz/dotfiles')
    }

    logRotator {
        numToKeep(100)
        daysToKeep(15)
    }

    scm {
        git {
            remote { url('https://github.com/jessfraz/dotfiles.git') }
            branches('*/master')
            extensions {
                wipeOutWorkspace()
                cleanAfterCheckout()
            }
        }
    }

    triggers {
        cron('H H */5 * *')
    }

    wrappers { colorizeOutput() }

    steps {
        shell('./bin/cleanup-non-running-images')
    }

    publishers {
        extendedEmail {
            recipientList('$DEFAULT_RECIPIENTS')
            contentType('text/plain')
            triggers {
                stillFailing {
                    attachBuildLog(true)
                }
            }
        }

        wsCleanup()
    }
}
