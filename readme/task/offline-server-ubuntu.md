- offline-server, is a dockerfile created, which is perfectly working fine

- I want you to just extract from that docker file
- But this time, we are going to directly install an ubuntu system, and directly on top of the ubuntu system we are going to install the pacakges, so try to make it as hands free as possible.
- Given a fresh ubuntu24, please install all the packages, and make it ready for me to use similar to the docker file in offline-server



NOTE: Please exclude graphana, promethus and that stack, please exclude fastapi and whatever server and nginx is planned
- i just want caddy, ssh, cloudflared installed
- make a folder in home/ubuntu called as exportable and paste the ssh file and stuff into it, whatever was currently exported out of the docker container
- also plan clearly how cloudflared token and stuff will be taken from the user. if everything needs to be setup as a .env file and pasted in advance that is also fine

- make a good readme of how to use everything 
- Create a folder called as offline-server-ubuntu24 and put all the sh files into it