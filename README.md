# docker-buildx

drone plugin to build docker image using `docker buildx` command

## settings

| key                   | required |    type     |  default  | description                                                                              |
|-----------------------|:--------:|:-----------:|:---------:|------------------------------------------------------------------------------------------|
| `registry`            |    N     |   String    | docker.io | used in `docker login` command, use docker hub if empty                                  |
| `username`            |    Y     |   String    |           | used in `docker login` command                                                           |
| `password`            |    Y     |   String    |           | used in `docker login` command                                                           |
| `repo`                |    Y     |   String    |           | `-t` option used in `docker buildx build` command without image tag                      |
| `platform`            |    N     |   String    |           | `--platform` option used in `docker buildx build` command, same as drone runner if empty |
| `cache`               |    N     | `none`,`s3` |   none    | enable cache                                                                             |
| `cache_s3_region`     |    N     |   String    | us-east-1 | see https://docs.docker.com/build/cache/backends/s3/                                     |
| `cache_s3_bucket`     |    Y     |   String    |           |                                                                                          |
| `cache_s3_endpoint`   |    Y     |   String    |           |                                                                                          |
| `cache_s3_access_key` |    Y     |   String    |           |                                                                                          |
| `cache_s3_secret_key` |    Y     |   String    |           |                                                                                          |
| `cache_mode`          |    N     | `min`,`max` |    min    | see https://docs.docker.com/build/cache/backends/#cache-mode                             |
| `cache_ignore_error`  |    N     |   Boolean   |   false   | ignore errors caused by failed cache exports.                                            |

## example

```yaml
steps:
  - name: docker buildx
    image: git.hd.caiweiqiang.cn:5001/drone-plugins/docker-buildx:latest
    privileged: true
    settings:
      registry: registry.xxx.com
      username: xxx
      password:
        from_secret: xxx
      repo: registry.xxx.com/path/to/repo
      platform: linux/amd64,linux/arm64
      cache: s3
      cache_s3_bucket: drone-ci-cache
      cache_s3_endpoint: https://minio.example.com
      cache_s3_access_key:
        from_secret: xxx
      cache_s3_secret_key:
        from_secret: xxx
      cache_mode: max
      cache_ignore_error: false
```
