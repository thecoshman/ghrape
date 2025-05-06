# ghrape
Ghrape (Grape) is a GitHub runner for ARM

## Usage

The intention is that you use docker-compose to create a stack that will run N containers using the image.
There's no auto-scaling here (yet?) you just need to define that the service is replicated with as many replicas as you wish.
Maybe I'll add auto-scaling, but for now, I just want to have a small pool of runners available.

An example compose file will be added at some stage.
