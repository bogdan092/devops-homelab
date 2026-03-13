
# 🚀 Bogdan's DevOps Datacenter (Homelab)

Welcome to my local, highly-available datacenter built from scratch on an HP Z4 Workstation. This project demonstrates a complete, modern DevOps lifecycle—from bare-metal infrastructure provisioning to Kubernetes orchestration and real-time monitoring.

## 🏗️ Architecture & Tech Stack

* **Hypervisor:** KVM / libvirt (Local virtualization)
* **Infrastructure as Code (IaC):** Terraform & Cloud-Init
* **Containerization:** Docker & Docker Compose
* **Orchestration:** Kubernetes (K3s - Multi-node cluster)
* **Package Management:** Helm
* **Monitoring & Observability:** Prometheus & Grafana
* **Version Control / GitOps:** GitHub

## 📂 Project Structure

1. `01-terraform/`
   * Contains the HCL code to communicate with KVM.
   * Provisions two virtual machines (`ubuntu` and `node-02`) with specific RAM/CPU limits.
   * Uses `cloud_init.cfg` to automatically inject SSH keys and install Docker on boot.
2. `02-docker-app/`
   * Contains a custom Nginx web application.
   * Features a dynamic HTML dashboard utilizing Mermaid.js to visualize the cluster's live architecture.
3. `03-kubernetes/`
   * Contains the YAML manifests for the K3s cluster.
   * Deploys the web app using a `ConfigMap` for distributed storage and a `Deployment` for high availability across the worker nodes.
   * Includes `Service` definitions (LoadBalancers) to expose the app on port `8080` and Grafana on port `3000`.

## ⚙️ How It Works

1. **Provisioning:** `terraform apply` builds the hardware and network.
2. **Clustering:** K3s is installed to link Node-01 (Control Plane) and Node-02 (Worker) into a single unified system.
3. **Deployment:** The website is injected into cluster memory via ConfigMap and replicated across both nodes to ensure zero-downtime if a node fails.
4. **Monitoring:** Helm deploys the `kube-prometheus-stack`. Prometheus automatically scrapes resource metrics from all pods and nodes, which are visualized in real-time on the Grafana dashboard.

## 🧹 Teardown

Because everything is defined as code, the entire datacenter can be cleanly destroyed, freeing up all local hardware resources in seconds:
```bash
cd 01-terraform
terraform destroy -auto-approve
