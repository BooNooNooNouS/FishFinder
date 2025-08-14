A single docker image is created to handle everything.  


ubuntu-py-3-12: Contains the basic os and python libraries to be able to pip install other stuff.
```bash
 docker build \
    -f docker_containers/Dockerfile.ubuntu-py-3-12 \
    -t ubuntu-python-3-12 \
    .
```
fishfinder: Uses ubuntu-py-3-12 to actually start the service.
```
docker build \
    -f docker_containers/Dockerfile.fishfinder \
    -t fishfinder \
    .
```

You can now run the entire stack:
```
docker-compose -f docker_containers/dev-docker-compose.yml up 
```


For all docker compose commands see [docker_install](/docs/docs/start/docker_install.md)