# Fusion-CRDB-Install

This installer serves 2 functions:

* Installation of Cockroach Database server to multiple nodes
* Installation of FusionPBX server to multiple nodes.

## CockroachDB Installation
Run the following commands on a Debian 10 or Ubuntu 20.04 server:

    apt install git
    git clone https://github.com/westparkcom/Fusion-CRDB-Install.git
    cd Fusion-CRDB-Install
    cp config.example.sh config.sh

Now you will need to edit **config.sh** and set all parameters according to your installation environment. PLEASE GO OVER THE WHOLE FILE, and uncomment any settings you wish to take effect.

Once you have completed the modifications to config.sh run the following command:

    bash installcrdb.sh

Follow any prompts exactly as they are explained to you. Run this script on all servers that you are installing cockroach onto.

## FusionPBX Installation
Run the following commands on a Debian 10 server:

    apt install git
    git clone https://github.com/westparkcom/Fusion-CRDB-Install.git
    cd Fusion-CRDB-Install
    cp config.example.sh config.sh

**NOTE**: You may want to just copy your config.sh file from your cockroach server instead of recreating it.

Once you have completed the modifications to config.sh run the following command:

    bash installfusion.sh

Follow any prompts exactly as they are explained to you. Run this script on all servers that you are installing FusionPBX onto.
