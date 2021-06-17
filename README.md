# piw-cross
Docker environment for cross compiling D code to the Raspberry Pi W. The Dockerfile is heavily inspired by [these](https://github.com/rracariu/docker).

## Usage

Build container locally:
```
podman build -t rpiw-cross
```

Run container and pass build commands. The following example uses dub to build a D project.

```
podman run --rm -ti -v $(pwd):/src localhost/rpiw-cross dub build --compiler=ldc-arm
```
