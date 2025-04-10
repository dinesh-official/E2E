# 🧠 ELK Stack Setup with Filebeat on Ubuntu 22.04

This guide outlines the step-by-step process to install and configure the **ELK Stack** (Elasticsearch, Logstash, Kibana) along with **Filebeat** and **NGINX** reverse proxy with basic authentication on an Ubuntu server.

---

## 🚀 Prerequisites

- Ubuntu 22.04 or later
- sudo/root access
- Open ports: `9200`, `5044`, `5601`, `80`, `443`

---

## 🔧 Step-by-Step Installation

### 1. Add Elastic GPG Key and APT Repo

```bash
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt update
```

---

### 2. Install and Configure Elasticsearch

```bash
sudo apt install elasticsearch
sudo nano /etc/elasticsearch/elasticsearch.yml
```

Make necessary changes in the config file, then:

```bash
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
curl -X GET "localhost:9200"
```

---

### 3. Install and Configure Kibana

```bash
sudo apt install kibana
sudo systemctl enable kibana
sudo systemctl start kibana
```

---

### 4. Set Up NGINX Reverse Proxy with Basic Auth for Kibana

```bash
sudo apt install nginx -y
sudo apt install apache2-utils
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
```

Create the reverse proxy config:

```bash
sudo nano /etc/nginx/sites-available/your_domain
```

Paste the following into the file (replace `your_domain` with your actual domain or IP):

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

Then link and test:

```bash
sudo ln -s /etc/nginx/sites-available/your_domain /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo ufw allow 'Nginx Full'
```

---

### 5. Install and Configure Logstash

```bash
sudo apt install logstash
```

Create input config:

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

Create output config:

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

Validate config:

```bash
sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
```

Start and enable Logstash:

```bash
sudo systemctl start logstash
sudo systemctl enable logstash
```

---

### 6. Install and Configure Filebeat

```bash
sudo apt install filebeat
sudo nano /etc/filebeat/filebeat.yml
```

> 🔧 Modify Filebeat output:
Comment out Elasticsearch output:

```yaml
#output.elasticsearch:
#  hosts: ["localhost:9200"]
```

Enable Logstash output:

```yaml
output.logstash:
  hosts: ["localhost:5044"]
```

Enable the system module:

```bash
sudo filebeat modules enable system
sudo filebeat test config
sudo systemctl start filebeat
sudo systemctl enable filebeat
```

---

## 🧩 Final Pipeline Overview

```text
System Logs → Filebeat → Logstash (localhost:5044) → Elasticsearch → Kibana (via NGINX)
```

---

## ✅ Done!

You now have a fully working ELK stack with Filebeat and secure Kibana access via NGINX!

> 💡 Tip: To view Kibana, open your browser at `http://<your-server-ip>` and log in using the credentials you set with `htpasswd`.

---

### 🔐 Basic Auth Sample

To regenerate or reset the password:

```bash
sudo htpasswd -c /etc/nginx/htpasswd.users kibanaadmin
```

---

### 🧠 Notes

- The Logstash `-t` command tests config syntax only and shows `Config Validation Result: OK` if it's correct.
- OpenJDK warnings like `UseConcMarkSweepGC deprecated` can be safely ignored.
