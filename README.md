# docker-buildx

drone plugin to build docker image using `docker buildx` command

## settings

| key        | required | value                                                                                    |
|------------|:--------:|------------------------------------------------------------------------------------------|
| `registry` |    N     | used in `docker login` command, use docker hub if empty                                  |
| `username` |    Y     | used in `docker login` command                                                           |
| `password` |    Y     | used in `docker login` command                                                           |
| `repo`     |    Y     | `-t` option used in `docker buildx build` command without image tag                      |
| `platform` |    N     | `--platform` option used in `docker buildx build` command, same as drone runner if empty |

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
```
