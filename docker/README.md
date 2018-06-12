# Pull the image
```
docker pull lennyt/cgraflow:latest
```

# Run an interactive session
```
docker run -it -t lennyt/cgraflow:latest /bin/bash
```
This drops you into the `/` directory, so you can `cd ~/CGRAFlow` to navigate
to the setup repository. You can run `make core_only` to validate that the
tests are passing on your setup. 

# Building an image
```
docker build . -t lennyt/cgraflow:latest
```

# Push an image
```
docker push lennyt/cgraflow:latest
```
