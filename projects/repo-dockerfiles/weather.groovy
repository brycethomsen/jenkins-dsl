freeStyleJob('weather') {
    displayName('weather')
    description('Build Dockerfiles in genuinetools/weather.')

    concurrentBuild()
    checkoutRetryCount(3)

    properties {
        githubProjectUrl('https://github.com/genuinetools/weather')
        sidebarLinks {
            link('https://hub.docker.com/r/jess/weather', 'Docker Hub: jess/weather', 'notepad.png')
            link('https://hub.docker.com/r/jessfraz/weather', 'Docker Hub: jessfraz/weather', 'notepad.png')
            link('https://r.j3ss.co/repo/weather/tags', 'Registry: r.j3ss.co/weather', 'notepad.png')
        }
    }

    logRotator {
        numToKeep(100)
        daysToKeep(15)
    }

    scm {
        git {
            remote {
                url('https://github.com/genuinetools/weather.git')
            }
            branches('*/master', '*/tags/*')
            extensions {
                wipeOutWorkspace()
                cleanAfterCheckout()
            }
        }
    }

    triggers {
        cron('H H * * *')
        githubPush()
    }

    wrappers { colorizeOutput() }

    environmentVariables(DOCKER_CONTENT_TRUST: '1')
    steps {
        shell('docker build --rm --force-rm -t r.j3ss.co/weather:latest .')
        shell('docker tag r.j3ss.co/weather:latest jess/weather:latest')
        shell('docker tag r.j3ss.co/weather:latest jessfraz/weather:latest')
        shell('docker push --disable-content-trust=false r.j3ss.co/weather:latest')
        shell('docker push --disable-content-trust=false jess/weather:latest')
        shell('docker push --disable-content-trust=false jessfraz/weather:latest')
        shell('for tag in $(git tag); do git checkout $tag; docker build  --rm --force-rm -t r.j3ss.co/weather:$tag . || true; docker push --disable-content-trust=false r.j3ss.co/weather:$tag || true; docker tag r.j3ss.co/weather:$tag jess/weather:$tag || true; docker push --disable-content-trust=false jess/weather:$tag || true; done')
        shell('docker rm $(docker ps --filter status=exited -q 2>/dev/null) 2> /dev/null || true')
        shell('docker rmi $(docker images --filter dangling=true -q 2>/dev/null) 2> /dev/null || true')
    }

    publishers {
        retryBuild {
            retryLimit(2)
            fixedDelay(15)
        }

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
