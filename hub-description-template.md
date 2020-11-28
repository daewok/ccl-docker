- [Supported Tags](#org7c941dd)
  - [Simple Tags](#org751c61c)
  - [Shared Tags](#orgf193352)
- [Quick Reference](#org3744b15)
- [What is CCL?](#orgec131c3)
- [How to use this image](#org2d3bcf0)
  - [Create a `Dockerfile` in your CCL project](#org0b0cdbe)
  - [Run a single Common Lisp script](#org73c6976)
  - [Developing using SLIME](#orgefdc49c)
- [Image variants](#orgba73c95)
  - [`%%IMAGE%%:<version>`](#org1fb4d00)
  - [`%%IMAGE%%:<version>-slim`](#org27b512e)
  - [`%%IMAGE%%:<version>-windowsservercore`](#org0ad43a4)
- [License](#orgead9ae0)



<a id="org7c941dd"></a>

# Supported Tags


<a id="org751c61c"></a>

## Simple Tags

INSERT-SIMPLE-TAGS


<a id="orgf193352"></a>

## Shared Tags

INSERT-SHARED-TAGS


<a id="org3744b15"></a>

# Quick Reference

-   **CCL Home Page:** [https://ccl.clozure.com/](https://ccl.clozure.com/)
-   **Where to file Docker image related issues:** <https://gitlab.common-lisp.net/cl-docker-images/ccl>
-   **Where to file issues for CCL itself:** [https://github.com/Clozure/ccl/issues](https://github.com/Clozure/ccl/issues)
-   **Maintained by:** [Eric Timmons](https://github.com/daewok/docker-ccl/)
-   **Supported architectures:** `linux/amd64`, `linux/arm/v7`, `windows/amd64`


<a id="orgec131c3"></a>

# What is CCL?

From [CCL's Home Page](https://ccl.clozure.com):

> Clozure CL (often called CCL for short) is a free Common Lisp implementation with a long history. Some distinguishing features of the implementation include fast compilation speed, native threads, a precise, generational, compacting garbage collector, and a convenient foreign-function interface.


<a id="org2d3bcf0"></a>

# How to use this image


<a id="org0b0cdbe"></a>

## Create a `Dockerfile` in your CCL project

```dockerfile
FROM %%IMAGE%%:latest
COPY . /usr/src/app
WORKDIR /usr/src/app
CMD [ "ccl", "--load", "./your-daemon-or-script.lisp" ]
```

You can then build and run the Docker image:

```console
$ docker build -t my-ccl-app
$ docker run -it --rm --name my-running-app my-ccl-app
```


<a id="org73c6976"></a>

## Run a single Common Lisp script

For many simple, single file projects, you may find it inconvenient to write a complete \`Dockerfile\`. In such cases, you can run a Lisp script by using the CCL Docker image directly:

```console
$ docker run -it --rm --name my-running-script -v "$PWD":/usr/src/app -w /usr/src/app %%IMAGE%%:latest ccl --load ./your-daemon-or-script.lisp
```


<a id="orgefdc49c"></a>

## Developing using SLIME

[SLIME](https://common-lisp.net/project/slime/) provides a convenient and fun environment for hacking on Common Lisp. To develop using SLIME, first start the Swank server in a container:

```console
$ docker run -it --rm --name ccl-slime -p 127.0.0.1:4005:4005 -v /path/to/slime:/usr/src/slime -v "$PWD":/usr/src/app -w /usr/src/app %%IMAGE%%:latest ccl --load /usr/src/slime/swank-loader.lisp --eval '(swank-loader:init)' --eval '(swank:create-server :dont-close t :interface "0.0.0.0")'
```

Then, in an Emacs instance with slime loaded, type:

```emacs
M-x slime-connect RET RET RET
```


<a id="orgba73c95"></a>

# Image variants

This image comes in several variants, each designed for a specific use case.


<a id="org1fb4d00"></a>

## `%%IMAGE%%:<version>`

This is the defacto image. If you are unsure about what your needs are, you probably want to use this one. It is designed to be used both as a throw away container (mount your source code and start the container to start your app), as well as the base to build other images off of.

Some of these tags may have names like buster or stretch in them. These are the suite code names for releases of Debian and indicate which release the image is based on. If your image needs to install any additional packages beyond what comes with the image, you'll likely want to specify one of these explicitly to minimize breakage when there are new releases of Debian.

These images are built off the buildpack-deps image. It, by design, has a large number of extremely common Debian packages.


<a id="org27b512e"></a>

## `%%IMAGE%%:<version>-slim`

This image does not contain the common packages contained in the default tag and only contains the minimal packages needed to run CCL. Unless you are working in an environment where only this image will be deployed and you have space constraints, we highly recommend using the default image of this repository.


<a id="org0ad43a4"></a>

## `%%IMAGE%%:<version>-windowsservercore`

This image is based on [Windows Server Core (`microsoft/windowsservercore`)](https://hub.docker.com/_/microsoft-windows-servercore). As such, it only works in places which that image does, such as Windows 10 Professional/Enterprise (Anniversary Edition) or Windows Server 2016.

For information about how to get Docker running on Windows, please see the relevant "Quick Start" guide provided by Microsoft:

-   [Windows Server Quick Start](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_server)
-   [Windows 10 Quick Start](https://msdn.microsoft.com/en-us/virtualization/windowscontainers/quick_start/quick_start_windows_10)


<a id="orgead9ae0"></a>

# License

CCL is licensed under the [Apache v2.0](https://www.apache.org/licenses/LICENSE-2.0).

The Dockerfiles used to build the images are licensed under BSD-2-Clause.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.