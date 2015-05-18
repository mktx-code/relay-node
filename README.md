# relay-node
Launch tor relay/bridge and bitcoin node on a fresh debian server.

This is a script to launch a tor relay or bridge (private/public), and to launch a bitcoin node running as a hidden service and/or a clearnet ip.

1. apt-get install git
2. cd relay-node
3. chmod +x install.sh
4. ./install.sh

Follow the prompts and answer the questions accordingly.

To do:
1. Add ipv6 support for tor relay.
2. Add electrum server creation. 
