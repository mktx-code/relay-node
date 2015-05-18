# relay-node
Launch tor relay/bridge and bitcoin node on a fresh debian server.

This is a script to launch a tor relay or bridge (private/public), and to launch a bitcoin node running as a hidden service and/or a clearnet ip.

1. apt-get install git -y
2. git clone https://github.com/mktx-code/relay-node
3. cd relay-node
4. chmod +x install 
5. ./install.sh

Follow the prompts and answer the questions accordingly.

To do:

1. Add ivp6 support for tor.
2. Add electrum install and config.
