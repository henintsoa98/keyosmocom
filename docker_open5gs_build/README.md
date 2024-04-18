This is the continuation of (docker_open5gs_build)[https://github.com/henintsoa98/docker_open5gs_build] \
This script is used to facilitate the provisionning of SIM CARD into HSS, AUC, SUBSCRIBER, IMS_SUBSCRIBER,and HLR without using Web UI, because it take to many time to add user into this five database one by one with some parameters. \
ensure that core and enodeb work, and :
```bash
git clone --depth 1 https://github.com/henintsoa98/keyosmocom && cd keyosmocom/docker_open5gs_build && bash setup.bash
```
after, for HLR :
```bash
cat OSMOHLR
```
Copy all of output.
Enter into docker process :
```bash
docker exec -it osmohlr /bin/bash
```
then connect to telnet :
```bash
telnet localhost 4258
```
enable :
```
enable
```
**AND PASTE HERE**, and exit two time
```
exit
```
