
echo "6. Generating signer BLS private key"
signer_bls_private_key=$(cargo run --bin key-gen | tail -n 1)
echo "Signer BLS Private Key: $signer_bls_private_key"

echo "7. Fetching VPS Public IP"
vps_ip=$(curl -s ifconfig.me)

echo "8. Enter other private keys"
read -p "Enter signer_eth_private_key: " signer_eth_private_key
read -p "Enter miner_eth_private_key: " miner_eth_private_key

echo "9. Configuring config.toml"
cat > $HOME/0g-da-node/config.toml <<EOF
log_level = "info"
data_path = "./db/"
encoder_params_dir = "params/"
grpc_listen_address = "0.0.0.0:34000"
eth_rpc_endpoint = "https://evmrpc-testnet.0g.ai"
socket_address = "${vps_ip}:34000"
da_entrance_address = "0x857C0A28A8634614BB2C96039Cf4a20AFF709Aa9"
start_block_number = 940000
signer_bls_private_key = "${signer_bls_private_key}"
signer_eth_private_key = "${signer_eth_private_key}"
miner_eth_private_key = "${miner_eth_private_key}"
enable_das = "true"
EOF

echo "10. Setting up systemd service"
sudo tee /etc/systemd/system/0gda.service > /dev/null <<EOF
[Unit]
Description=0G-DA Node
After=network.target

[Service]
User=root
Environment="RUST_BACKTRACE=full"
Environment="RUST_LOG=debug"
WorkingDirectory=$HOME/0g-da-node
ExecStart=$HOME/0g-da-node/target/release/server --config $HOME/0g-da-node/config.toml
Restart=always
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

echo "11. Starting 0G-DA Node service"
sudo systemctl daemon-reload
sudo systemctl enable 0gda
sudo systemctl start 0gda
sudo journalctl -u 0gda -f -o cat

sed -i 's|^eth_rpc_endpoint *= *".*"|eth_rpc_endpoint = "https://evm-0g.winnode.xyz"|' $HOME/0g-da-node/config.toml
grep '^eth_rpc_endpoint' $HOME/0g-da-node/config.toml
sleep 5
sudo systemctl restart 0gda
sudo journalctl -u 0gda -f -o cat
