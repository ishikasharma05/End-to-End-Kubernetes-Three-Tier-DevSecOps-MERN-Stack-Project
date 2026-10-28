# End-to-End Kubernetes Three-Tier DevSecOps Project (MERN on AWS EKS)

A three-tier web application (ReactJS frontend, NodeJS backend, MongoDB database) deployed on **AWS EKS** with infrastructure as code, a security-scanning CI pipeline, GitOps delivery, and cluster monitoring.

> Built as an assignment for DevOps Institute Mumbai. The application source comes from the institute's starter repository; all infrastructure, pipelines, manifests and monitoring in this repo were written and deployed by me.

![Architecture](docs/architecture.png)

## What this project demonstrates

| Area | Tool | What it does here |
|---|---|---|
| Infrastructure as Code | Terraform | Creates the Jenkins server and the EKS cluster (VPC, subnets, NAT, node group, IAM) |
| CI | Jenkins | Builds, scans and publishes container images on every run |
| Code quality | SonarQube 9.9 | Static analysis and a Quality Gate wired back to Jenkins through a webhook |
| Security scanning | Trivy, OWASP Dependency-Check | Filesystem and image vulnerability scans (Dependency-Check runs on demand) |
| Registry | Amazon ECR | Private repositories for the frontend and backend images |
| Orchestration | Amazon EKS (Kubernetes 1.34) | Runs the three tiers with replicas, probes and persistent storage |
| Ingress | AWS Load Balancer Controller | Turns a Kubernetes Ingress into an internet-facing Application Load Balancer |
| GitOps | ArgoCD | Watches this repo and keeps the cluster in sync with the manifests |
| Monitoring | Prometheus and Grafana (kube-prometheus-stack) | Metrics, dashboards and an alert rule |

## Architecture and flow

1. A Jenkins pipeline checks out the code, runs SonarQube analysis and the Quality Gate, installs dependencies, runs Trivy on the files, builds the Docker image, pushes it to ECR, and scans the pushed image with Trivy.
2. The last pipeline stage edits the image tag in `Kubernetes-Manifests/<tier>/deployment.yaml` and pushes that commit to GitHub.
3. ArgoCD detects the new commit and rolls the new image out to the `three-tier` namespace, with automated sync, prune and self-heal enabled.
4. Users reach the app through an Application Load Balancer. The Ingress sends `/api` to the backend and everything else to the frontend.
5. Prometheus scrapes the cluster, Grafana shows the dashboards, and a `PrometheusRule` alerts when the backend drops below two available replicas.

## Repository layout

```
Application-Code/        Frontend (React) and backend (Node/Express) source and Dockerfiles
Jenkins-Server-TF/       Terraform: Jenkins EC2 server (Jenkins, Docker, Terraform, kubectl, Helm, Trivy, SonarQube)
EKS-TF/                  Terraform: VPC, EKS cluster, managed node group, EBS CSI driver, load balancer controller IAM role
Jenkins-Pipeline/        Jenkinsfile-Backend and Jenkinsfile-Frontend
Kubernetes-Manifests/    Namespace, MongoDB (PVC), backend, frontend, Ingress
ArgoCD/                  ArgoCD Application definition
Monitoring/              Prometheus alert rule
docs/                    Architecture diagram and screenshots
```

## Key design choices

- **Region:** `ap-south-1` (Mumbai).
- **Network:** a dedicated VPC (`10.1.0.0/16`) with two public and two private subnets across two availability zones and a single shared NAT gateway to keep cost down. Worker nodes live in the private subnets.
- **Nodes:** managed node group on `m7i-flex.large` (2 vCPU, 8 GiB), Amazon Linux 2023. This instance type was chosen because the account only allows Free Tier eligible types.
- **Database:** MongoDB 4.4.6 as a single-replica deployment with a 2 GiB `gp3` EBS volume (`ebs-gp3` StorageClass, `WaitForFirstConsumer`). Credentials are stored in a Kubernetes Secret created from the command line and are never committed to Git.
- **Backend:** reads `MONGO_CONN_STR`, `USE_DB_AUTH`, `MONGO_USERNAME` and `MONGO_PASSWORD` from the environment; three replicas, TCP readiness and liveness probes.
- **Frontend:** uses the relative URL `/api/tasks`, so it needs no knowledge of the load balancer address.
- **Access to ArgoCD, Grafana and Prometheus:** through `kubectl port-forward` instead of public load balancers.
- **Jenkins and SonarQube:** only reachable from the author's IP through the security group.

## How to reproduce

Prerequisites: an AWS account with admin access, and AWS CLI, Terraform, kubectl, Helm and Git installed locally.

### 1. Jenkins server

```bash
cd Jenkins-Server-TF
terraform init
terraform apply -var="my_ip=<YOUR_PUBLIC_IP>/32"
```
Wait about 8 minutes for the install script. Then open Jenkins on port 8080 and SonarQube on port 9000, and configure:

- Jenkins plugins: NodeJS, SonarQube Scanner, OWASP Dependency-Check, Eclipse Temurin installer, Docker Pipeline, Pipeline: AWS Steps, Prometheus metrics, Pipeline Stage View
- Credentials: `github`, `sonar-token`, `ACCOUNT_ID`, `ECR_REPO1` (`frontend`), `ECR_REPO2` (`backend`), `nvd-api-key`
- Tools: `jdk` (17), `nodejs`, `sonar-scanner`, `DP-Check`
- SonarQube server `sonar-server` using the server's private IP, plus a webhook to `http://<private-ip>:8080/sonarqube-webhook/`
- Two pipeline jobs from SCM, pointing at `Jenkins-Pipeline/Jenkinsfile-Backend` and `Jenkins-Pipeline/Jenkinsfile-Frontend`

### 2. Container registry

```bash
aws ecr create-repository --repository-name frontend --region ap-south-1
aws ecr create-repository --repository-name backend --region ap-south-1
```
Run both pipelines once to push the first images.

### 3. EKS cluster

```bash
cd EKS-TF
terraform init
terraform apply
aws eks update-kubeconfig --region ap-south-1 --name three-tier-eks
kubectl get nodes
```

### 4. AWS Load Balancer Controller

```bash
helm repo add eks https://aws.github.io/eks-charts && helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system \
  --set clusterName=three-tier-eks --set region=ap-south-1 \
  --set vpcId=$(terraform output -raw vpc_id) \
  --set serviceAccount.create=true --set serviceAccount.name=aws-load-balancer-controller \
  --set "serviceAccount.annotations.eks\.amazonaws\.com/role-arn=$(terraform output -raw lb_controller_role_arn)"
```

### 5. Application

```bash
kubectl apply -f Kubernetes-Manifests/namespace.yaml
kubectl create secret generic mongo-sec -n three-tier \
  --from-literal=username=<db-user> --from-literal=password=<db-password>
kubectl apply -f Kubernetes-Manifests/Database/
kubectl apply -f Kubernetes-Manifests/Backend/
kubectl apply -f Kubernetes-Manifests/Frontend/
kubectl apply -f Kubernetes-Manifests/ingress.yaml
```
The app is available on the Ingress address (`kubectl get ingress -n three-tier`).

### 6. GitOps

```bash
kubectl create namespace argocd
kubectl apply -n argocd --server-side --force-conflicts \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f ArgoCD/application.yaml
```

### 7. Monitoring

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace \
  --set grafana.adminPassword='<choose-a-password>' \
  --set prometheus.prometheusSpec.retention=6h
kubectl apply -f Monitoring/alerts.yaml
```

## CI pipeline stages

Cleaning workspace, checkout, SonarQube analysis, Quality Gate, install dependencies, OWASP Dependency-Check (optional, enabled with the `RUN_DEPCHECK` build parameter), Trivy file scan, Docker build, push to ECR, Trivy image scan, update the deployment manifest and push to Git.

## Security findings (DevSecOps)

- **Outdated base image:** Trivy reports that the `node:14` images run on Debian 10, which is no longer supported, and lists many HIGH and CRITICAL findings. The pipeline reports them without failing the build. The recommended fix is a supported Node base image with matching dependency updates.
- **Dependencies:** `npm install` reports known vulnerabilities in the backend dependencies, and Trivy flags packages such as `qs` and `path-to-regexp`.
- **SonarQube:** no bugs or vulnerabilities, with two security hotspots reviewed manually. The Quality Gate failed at first because those hotspots were unreviewed.
- **Secrets:** no secrets in Git. Database credentials are created directly in the cluster, and CI credentials live in Jenkins.

## Monitoring

Grafana dashboards (Kubernetes / Compute Resources / Namespace (Pods) for the `three-tier` namespace, and Node Exporter) show CPU and memory of every tier. The `BackendPodsUnavailable` rule fires when fewer than two backend replicas are available. Load was generated against the Ingress address and a backend pod was deleted to show it being replaced.

## Problems encountered and how they were fixed

| Problem | Cause | Fix |
|---|---|---|
| Jenkins failed to install | Jenkins rotated its apt signing key, and the script used the old one | Switched to the 2026 key and Java 21 |
| SonarQube container restart loop | Missing kernel setting | Set `vm.max_map_count` and `fs.file-max` in the install script |
| Large file rejected by GitHub | The `.terraform` provider binary was committed | Added `.gitignore`, reset the local commits and re-committed without it |
| Pipeline: tool not found | Tool names did not match the Jenkinsfile | Created `jdk`, `nodejs`, `sonar-scanner` and `DP-Check` with exact names |
| ECR push: repository does not exist | A typo in the `ECR_REPO2` credential | Re-entered the credential |
| SonarQube connection timed out, then a URL error | Public IP and a stray space in the server URL | Used the private IP and removed the space |
| Node errors during analysis and build | Newest Node and JDK were selected in the tool config | Pinned versions and installed `libatomic1` |
| Dependency-Check failed | NVD now requires an API key, and the first full download is slow | Added an NVD key and made the stage optional through a build parameter |
| EKS node group failed | Account only allows Free Tier eligible instance types | Switched to `m7i-flex.large` |
| ArgoCD pod Pending | Not enough room on two nodes | Scaled the node group to three nodes |
| Deployment-update stage failed | `npm install` modified `package-lock.json`, blocking `git pull --rebase` | Added `--autostash` to the pull |

## Cost and cleanup

While running, the cluster costs money for the EKS control plane, worker nodes, NAT gateway, load balancer and the Jenkins server. Stop the Jenkins instance when idle. To remove the cluster completely:

```bash
kubectl delete -f ArgoCD/application.yaml
kubectl delete ingress three-tier-ingress -n three-tier
# wait until the load balancer is gone: aws elbv2 describe-load-balancers --region ap-south-1
helm uninstall monitoring -n monitoring
kubectl delete namespace monitoring three-tier argocd
helm uninstall aws-load-balancer-controller -n kube-system
cd EKS-TF && terraform destroy
```

## Screenshots

Add your screenshots to `docs/screenshots/` and reference them here, for example:

- Jenkins stage views for both pipelines

- SonarQube project dashboards

- `kubectl get nodes` and `kubectl get pods,svc,pvc,ingress -n three-tier`
- The running application
- ArgoCD application tree
- Grafana dashboard 

## Author

Ishika Sharma, [github.com/ishikasharma05](https://github.com/ishikasharma05)