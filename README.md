# Elasticsearch Installation on Ubuntu

This guide explains how to install Elasticsearch on an Ubuntu server and set it up as part of your logging stack.

## Prerequisites

- A fresh Ubuntu 22.04 server
- Sudo privileges
- An internet connection

## Steps to Install Elasticsearch

### Step 1: Install Dependencies

Ensure that you have the necessary dependencies installed:

```bash
sudo apt update
sudo apt install wget apt-transport-https
```

### Step 2: Add the Elastic APT Repository

Download and install the Elastic GPG key:

```bash
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
```

Add the Elastic repository to your system's list of APT sources:

```bash
sudo sh -c 'echo "deb https://artifacts.elastic.co/packages/8.x/apt stable main" > /etc/apt/sources.list.d/elastic-8.x.list'
```

### Step 3: Update the Package List

Refresh the APT package index to include the new repository:

```bash
sudo apt update
```

### Step 4: Install Elasticsearch

Install the latest version of Elasticsearch:

```bash
sudo apt install elasticsearch
```

### Step 5: Start and Enable Elasticsearch

Start the Elasticsearch service and enable it to run at startup:

```bash
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch
```

### Step 6: Verify Elasticsearch is Running

Check the status of the Elasticsearch service:

```bash
sudo systemctl status elasticsearch
```

If it's running, the status should show `active (running)`.

### Step 7: Test Elasticsearch

To verify that Elasticsearch is working correctly, use the following `curl` command:

```bash
curl -X GET "localhost:9200/"
```

This should return a JSON response with details about your Elasticsearch instance.

---

## Next Steps

Once Elasticsearch is installed and running, you can proceed to install Kibana and Filebeat as part of your logging stack setup.

Let me know if you encounter any issues during the installation process!
