# LXCA
One line installation of Lenovo XClarity Administrator for Docker.

Ubuntu focused.

Run as root.

Make a Docker Compose directory.

rm installlxca.sh &> /dev/null; wget https://github.com/echovang/lxca/raw/main/installlxca.sh && bash installlxca.sh

Image and YAML source: https://datacentersupport.lenovo.com/us/en/solutions/lnvo-lxcaupd

docker-compose.yml network setting is modified to join an existing macvlan vs creating one. This is to allow the script to be reused to deploy additional LXCA containers on the same network. The script creates the macvlan if one isn't present.

You can stop the script at "Enter the parent network interface" prompt to edit the docker-compose.yml file to your requirements and run the script again to continue.

Advance installation and IPv6: https://sysmgt.lenovofiles.com/help/topic/com.lenovo.lxca.doc/setup_vm_physicallyseparatenetwork_step6_installlxca_docker.html?cp=1_5_0_1_1_5_2
