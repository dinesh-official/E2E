#!/bin/bash

echo "🚀 Starting ELK Stack Setup on Ubuntu..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install apt-transport-https curl gnupg -y

# Import Elastic GPG key
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | \
  sudo gpg --dearmor -o /usr/share/keyrings/elastic-archive-keyring.gpg

# Add Elastic repository
echo "deb [signed-by=/usr/share/keyrings/elastic-archive-keyring.gpg] \
https://artifacts.elastic.co/packages/8.x/apt stable main" | \
sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# Update repo again
sudo apt update

# Install Elasticsearch
sudo apt install elasticsearch -y
sudo sed -i "s|#network.host: .*|network.host: localhost|" /etc/elasticsearch/elasticsearch.yml
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# Install Kibana
sudo apt install kibana -y
sudo sed -i "s|#server.host: .*|server.host: \"localhost\"|" /etc/kibana/kibana.yml
sudo sed -i "s|#elasticsearch.hosts: .*|elasticsearch.hosts: [\"http://localhost:9200\"]|" /etc/kibana/kibana.yml
sudo systemctl enable kibana
sudo systemctl start kibana

# Install Logstash
sudo apt install logstash -y

# Sample Logstash pipeline config
cat <<EOF | sudo tee /etc/logstash/conf.d/simple.conf
input {
  beats {
    port => 5044
  }
}
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    index => "logstash-%{+YYYY.MM.dd}"
  }
}
EOF

sudo systemctl enable logstash
sudo systemctl start logstash

# Install Filebeat
sudo apt install filebeat -y

# Enable Filebeat → Logstash output
sudo sed -i 's|#output.logstash:|output.logstash:|' /etc/filebeat/filebeat.yml
sudo sed -i 's|#  hosts: \["localhost:5044"\]|  hosts: ["localhost:5044"]|' /etc/filebeat/filebeat.yml

sudo systemctl enable filebeat
sudo systemctl start filebeat

echo "✅ ELK Stack setup complete!"
echo "➡️  Access Kibana: http://localhost:5601"
