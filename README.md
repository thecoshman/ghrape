# ghrape
Ghrape (Grape) is a GitHub runner for ARM

This repo offers a Docker image that can be used to run a [self-hosted GitHub runner](https://docs.github.com/en/actions/hosting-your-own-runners/managing-self-hosted-runners/about-self-hosted-runners) to use in your repos.
Due to how GitHub allows registering runners, when not setup as an organisation, you cannot share runners across all your projects;
instead, for each of your repositories you wish to have self hosted runners, you must start a runner for each.
GitHub does offer, as a preview currently, ARM based runners, but those can only be used for public repositories.

## Who/What is this for?

Are you looking for:
* ARM64 based runners
* for private repositories
* and you are happy _not_ sharing runners across repos
* and happy with a 'fixed' number of runners per repo

Then this _might_ just be a solution for you.
If you are looking for something more complex, like auto-scaling, you sadly might need to keep up with the hunt, or raise an issue!

## Usage

Bringing up a single container will register a single runner within a GitHub repository.
The runner will end up with with three automatically applied labels; `self-hosted`, `Linux` and `ARM64`.
Its name will be auto-generated to something like `d2c477aee719`.

At container start, an API call is made to automatically get a short-lived token to register the runner;
and when the container is stopped, an API call is again made to get a short-lived token to remove the runner from the repository.

The container requires three environment variables as described:

| env variable | description |
| --- | --- |
| `GH_USER` | GitHub user for the runners, in my case `thecoshman` |
| `GH_REPO` | The repository, owned by the user, you want the runner for, ie `ghrape` |
| `GH_PAT` | A fine-grained token with (at least) "Administration" repository permissions (write) |

See the GitHub API docs for more information about the [registration](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-registration-token-for-a-repository) and [removal](https://docs.github.com/en/rest/actions/self-hosted-runners?apiVersion=2022-11-28#create-a-remove-token-for-a-repository) API calls that are made.

Note that examples below have a volume mount for `docker.sock`, this allows the runners to perform docker based operations.
If you do not want this, I believe you can simply not use the volume mount, and whilst docker is installed, it can't be used. 
You might find you permission denied errors, which can be solved by running (on your host machine) `sudo chmod 666 /var/run/docker.sock`, as described [here](https://devopscube.com/run-docker-in-docker/).
Further, as described on that page, you likely also need to update `/etc/rc.local` so it is applied at system start up.

### Directly running a container (mediocre solution)

You can directly run a single container from the image using the following example command:

```
docker run \
  -i -t \
  --env GH_USER=thecoshman \
  --env GH_REPO=ghrape \
  --env GH_PAT=github_pat_123456 \
  --volume /var/run/docker.sock:/var/run/docker.sock \
  --name ghrape_runner \
  ghcr.io/thecoshman/ghrape:latest
```

### Using Docker Compose (recommended solution)

The intention is that you use docker-compose to create a stack that will run N containers using the image.
There's no auto-scaling here (yet?) you just need to define that the service is replicated with as many replicas as you wish.
Maybe I'll add auto-scaling, but for now, I just want to have a small pool of runners available.

Here is an example Docker compose that could be used to run three runners for this repository:
```
services:
  runners:
    image: ghcr.io/thecoshman/ghrape:latest
    restart: unless-stopped
    environment:
      - GH_USER=thecoshman
      - GH_REPO=ghrape
      - GH_PAT=github_pat_123456
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    deploy:
      mode: replicated
      replicas: 3
```
(Note: As this project is public, I just make use of the GitHub provided runners)

## Image Versioning and Updating (Watchtower?)

Each time the `main` branch is built, the resulting image is tagged with `latest` and the github runner code version, extracted form the `Dockerfile`, for example `2.235.0`.

My intention/suggestion is that you only use the `latest` tag, as the runner code is self updating anyway.
This means each time you pull the `latest` image, you are getting the most recent version of the code, reducing the 'catch up' that the runner needs to do.
In theory, as the runner code self updates, you can get away with deploying containers once and letting them update for years.
It's to be tested, but I believe using a utility, like Watchtower, would be a good idea, ensuring each time this image is updated, it's pulled and deployed for you locally.

## TODO

Things I'm aware of and would like to fix/improve at some stage

### Auto-update!

The `main` branch is automatically built and tagged with the runner version, extracted form the `Dockerfile`.
I need to add a workflow that can frequently check what the latest version of the runner code is, and if newer than what is currently used, commit that, thus triggering a new image to be built.
If I'm not mistaken, having a workflow commit code changes will prevent another workflow from triggering, so probably need to refactor the workflows a little bit.
The `build-image` image workflow should be a re-usable one, that can be called either from a (none automated) push to main (a new workflow), or form the (yet to be implemented) version bump running.

### Review Debian packages

The list of packages installed in the Dockerfile were taken from the example that I initially found;
I would guess I don't really need them all, so at some stage, I'd look to test removing them and see if the runner still works.

### Multi-stage build

In the interest in reducing the final build image, I would suspect I could make use of multi-stage build to install tools required _purely_ for the build phase.
Investigation required...

### License

This is open source, I've not really invented anything special here, so I really should slap on a proper license to that affect.
Until I get around to that, please do feel free to take this and use it as you wish.
That said, contributions to help improve this would always be appreciated.
