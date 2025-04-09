# 📘 ELK Stack + Filebeat + NGINX Setup on Ubuntu

This README file documents the detailed step-by-step installation and configuration of the **ELK Stack (Elasticsearch, Logstash, Kibana)** with **Filebeat** and **NGINX** as a reverse proxy on **Ubuntu 22.04/24.04**. It is fully optimized for copy-paste and GitHub.

---

## 📦 1. Install Elasticsearch

```bash
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg

echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

sudo apt update
sudo apt install elasticsearch -y
```

Edit the file and set:

```yaml

echo -e "network.host: localhost\nhttp.port: 9200\ndiscovery.type: single-node" | sudo tee -a /etc/elasticsearch/elasticsearch.yml

```

Then:

```bash
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
curl -X GET "localhost:9200"
```

---

## 📊 2. Install Kibana

```bash
sudo apt install kibana -y
sudo nano /etc/kibana/kibana.yml
```

Set the following:

```yaml
server.host: "localhost"
elasticsearch.hosts: ["http://localhost:9200"]
```

```bash
sudo systemctl enable kibana
sudo systemctl start kibana
```

---

## 🌐 3. Set Up NGINX with Basic Auth for Kibana

```bash
sudo apt install nginx apache2-utils -y
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
```

To update password:

```bash
sudo htpasswd /etc/nginx/htpasswd.users newusername
```

Configure NGINX:

```bash
sudo nano /etc/nginx/sites-available/kibana
```

Paste:

```nginx
server {
    listen 80;
    server_name your_domain_or_ip;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
sudo ln -s /etc/nginx/sites-available/kibana /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 'Nginx Full'
```

---

## 🔄 4. Install Logstash

```bash
sudo apt install logstash -y
```

**Input Configuration:**

```bash
sudo nano /etc/logstash/conf.d/02-beats-input.conf
```

```conf
input {
  beats {
    port => 5044
  }
}
```

**Output Configuration:**

```bash
sudo nano /etc/logstash/conf.d/30-elasticsearch-output.conf
```

```conf
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
```

**Start Logstash:**

```bash
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
sudo systemctl enable logstash
sudo systemctl start logstash
sudo ufw allow 5044
```

---

## 📥 5. Install and Configure Filebeat

```bash
sudo apt install filebeat -y
sudo filebeat modules enable system
sudo filebeat test config
sudo nano /etc/filebeat/filebeat.yml
```

Update the following:

```yaml
output.logstash:
  hosts: ["localhost:5044"]

setup.kibana:
  host: "localhost:5601"
```

Then:

```bash
sudo systemctl enable filebeat
sudo systemctl start filebeat
```

**Optional Dashboards Setup:**

```bash
sudo filebeat setup --pipelines --modules system
sudo filebeat setup -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601
```

---

## ✅ 6. Verify Logs in Elasticsearch

```bash
curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'
```

Open Kibana in browser:

```
http://your_domain_or_ip
```

Login with Kibana user created in htpasswd.

---

## 🔀 Log Flow Diagram

```
System Logs → Filebeat → Logstash (localhost:5044) → Elasticsearch → Kibana (via NGINX)
```

---

## 📂 Network Address Translation (NAT) Notes

- Expose NGINX (port 80) publicly for Kibana.
- Allow port 5044 for Filebeat input.
- Use firewall rules to restrict access.
- Consider using SSL and domain-based access for production.

---

## 📝 View Kibana Auth File

```bash
cat /etc/nginx/htpasswd.users
```

---

## 📘 GitHub Project Summary

```markdown
# ELK Stack with Filebeat & NGINX

Install and configure ELK stack with Filebeat and secure Kibana via NGINX.

## Components:
- Elasticsearch
- Logstash
- Kibana
- Filebeat
- NGINX with HTTP Auth

## Access
- Kibana: http://your_domain_or_ip
- User: kibanaadmin

## Flow
System Logs → Filebeat → Logstash → Elasticsearch → Kibana

## License
MIT
```

---

> 🟢 All commands are ready for one-click copy-paste.
