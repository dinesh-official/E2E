# 🚀 ELK Stack + Filebeat + NGINX Setup on Ubuntu

This guide documents step-by-step commands to install and configure the ELK (Elasticsearch, Logstash, Kibana) stack with Filebeat and NGINX as a reverse proxy on Ubuntu 22.04/24.04.

---

## 📦 1. Install Elasticsearch

```bash
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
sudo apt install elasticsearch -y
sudo nano /etc/elasticsearch/elasticsearch.yml
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch
curl -X GET "localhost:9200"
```

---

## 📊 2. Install Kibana

```bash
sudo apt install kibana -y
sudo systemctl enable kibana
sudo systemctl start kibana
```

---

## 🌐 3. Set Up NGINX with Basic Auth for Kibana

```bash
sudo apt install nginx apache2-utils -y
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
sudo nano /etc/nginx/sites-available/your_domain
```

Paste the config below (replace `your_domain`):

```nginx
server {
    listen 80;
    server_name your_domain;

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
sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 'Nginx Full'
```

---

## 🔄 4. Install Logstash

```bash
sudo apt install logstash -y
sudo nano /etc/logstash/conf.d/02-beats-input.conf
```

Paste:

```conf
input {
  beats {
    port => 5044
  }
}
```

```bash
sudo nano /etc/logstash/conf.d/30-elasticsearch-output.conf
```

Paste:

```conf
output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
```

```bash
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
sudo systemctl start logstash
sudo systemctl enable logstash
```

---

## 📥 5. Install and Configure Filebeat

```bash
sudo apt install filebeat -y
sudo filebeat modules enable system
sudo filebeat test config
sudo nano /etc/filebeat/filebeat.yml
sudo systemctl start filebeat
sudo systemctl enable filebeat
sudo filebeat setup --pipelines --modules system
sudo filebeat setup -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
sudo filebeat setup -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601
```

---

## ✅ 6. Verify Logs in Elasticsearch

```bash
curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'
```

---

## 🔁 Log Flow Diagram

```
System Logs → Filebeat → Logstash (localhost:5044) → Elasticsearch → Kibana (via NGINX)
```

---

## 📝 Optional: View Auth File

```bash
cat /etc/nginx/htpasswd.users
```

---

> ✅ This guide supports ELK stack v7.x on Ubuntu 22.04/24.04.
