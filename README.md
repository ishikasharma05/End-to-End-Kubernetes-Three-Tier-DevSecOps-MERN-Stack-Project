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

<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1700 1090" width="1700" height="1090" font-family="DejaVu Sans, Arial, Helvetica, sans-serif" xmlns:c2pa="http://c2pa.org/manifest"><metadata><c2pa:manifest>AAAWgmp1bWIAAAAeanVtZGMycGEAEQAQgAAAqgA4m3EDYzJwYQAAABZcanVtYgAAAEdqdW1kYzJtYQARABCAAACqADibcQN1cm46YzJwYTpiNzNkOTdkZC1jYTE1LTQyMTEtOThmOC0xNGMyYmRkYzRlMjAAAAADl2p1bWIAAAApanVtZGMyYXMAEQAQgAAAqgA4m3EDYzJwYS5hc3NlcnRpb25zAAAAALxqdW1iAAAARGp1bWRjYm9yABEAEIAAAKoAOJtxE2MycGEuaW5ncmVkaWVudC52MwAAAAAYYzJzaJqiBXSbeAbe2vX09bH/M/wAAABwY2JvcqNpZGM6Zm9ybWF0bWltYWdlL3N2Zyt4bWxqaW5zdGFuY2VJRHgseG1wOmlpZDpkMTYwY2JlYy1kYWJjLTQ5ODAtYjU1NC1jYmM5YTM4NDEzY2NscmVsYXRpb25zaGlwaHBhcmVudE9mAAAB4mp1bWIAAABBanVtZGNib3IAEQAQgAAAqgA4m3ETYzJwYS5hY3Rpb25zLnYyAAAAABhjMnNoVP8DXnQGHQku/P5gG3wSgQAAAZljYm9yomdhY3Rpb25zgqJmYWN0aW9ua2MycGEub3BlbmVkanBhcmFtZXRlcnOha2luZ3JlZGllbnRzgaJjdXJseC1zZWxmI2p1bWJmPWMycGEuYXNzZXJ0aW9ucy9jMnBhLmluZ3JlZGllbnQudjNkaGFzaFggFwiThDXv9bdItbr7JoVF6BWuCUCjYVM/SaDewBwFMQakZmFjdGlvbngdY29tLmFudGhyb3BpYy5jbGF1ZGUucHJvdmlkZWRqcGFyYW1ldGVyc6F4H2NvbS5hbnRocm9waWMub3JpZ2luLWNvbmZpZGVuY2VndW5rbm93bmtkZXNjcmlwdGlvbnhmQ2xhdWRlIHByb3ZpZGVkIHRoaXMgZmlsZSBhdCB0aGUgcmVxdWVzdCBvZiBhIHVzZXIgYW5kIG1heSBoYXZlIGNyZWF0ZWQgb3IgbW9kaWZpZWQgdGhlIGZpbGUgY29udGVudHMubXNvZnR3YXJlQWdlbnShZG5hbWVmQ2xhdWRlcmFsbEFjdGlvbnNJbmNsdWRlZPUAAADIanVtYgAAAEBqdW1kY2JvcgARABCAAACqADibcRNjMnBhLmhhc2guZGF0YQAAAAAYYzJzaNtDtKJIuBbTqzC59+saCi4AAACAY2JvcqVjYWxnZnNoYTI1NmNwYWRNAAAAAAAAAAAAAAAAAGRoYXNoWCChf1eL6IEAlNZD3i/HoD/5KbKdBZ3l2hum0aq/WzQ6d2RuYW1lbmp1bWJmIG1hbmlmZXN0amV4Y2x1c2lvbnOBomVzdGFydBjSZmxlbmd0aBkeBAAAAj5qdW1iAAAAJ2p1bWRjMmNsABEAEIAAAKoAOJtxA2MycGEuY2xhaW0udjIAAAACD2Nib3KlY2FsZ2ZzaGEyNTZpc2lnbmF0dXJleE1zZWxmI2p1bWJmPS9jMnBhL3VybjpjMnBhOmI3M2Q5N2RkLWNhMTUtNDIxMS05OGY4LTE0YzJiZGRjNGUyMC9jMnBhLnNpZ25hdHVyZWppbnN0YW5jZUlEeCx4bXA6aWlkOmZlNzJlYWUzLTVhYmUtNDU4YS05OWJiLTBiYjBhNTg5ODFmY3JjcmVhdGVkX2Fzc2VydGlvbnODomN1cmx4LXNlbGYjanVtYmY9YzJwYS5hc3NlcnRpb25zL2MycGEuaW5ncmVkaWVudC52M2RoYXNoWCAXCJOENe/1t0i1uvsmhUXoFa4JQKNhUz9JoN7AHAUxBqJjdXJseCpzZWxmI2p1bWJmPWMycGEuYXNzZXJ0aW9ucy9jMnBhLmFjdGlvbnMudjJkaGFzaFgga9ohJ1IzWUtU9sa3s6VgIXyuyhODujx3Qy/VA9PejA6iY3VybHgpc2VsZiNqdW1iZj1jMnBhLmFzc2VydGlvbnMvYzJwYS5oYXNoLmRhdGFkaGFzaFggW7rNm3MAkkDRxFNbjyb5QWCck7AmJno/Z2w54JTJvsR0Y2xhaW1fZ2VuZXJhdG9yX2luZm+jZG5hbWVvQW50aHJvcGljIEZpbGVzZ3ZlcnNpb25lMS4wLjBrc3BlY1ZlcnNpb25lMi40LjAAABA4anVtYgAAAChqdW1kYzJjcwARABCAAACqADibcQNjMnBhLnNpZ25hdHVyZQAAABAIY2JvctKEWQISogEmGCFZAgowggIGMIIBjaADAgECAhRA5aAK7sI50L64g/oGQgU9Z1UTADAKBggqhkjOPQQDAzBJMRcwFQYDVQQKEw5BbnRocm9waWMsIFBCQzEuMCwGA1UEAxMlQW50aHJvcGljIENvbnRlbnQgQ3JlZGVudGlhbHMgUm9vdCBDQTAeFw0yNjA4MDcxODQzNTZaFw0yODA4MDYxOTQzNTZaMEQxFzAVBgNVBAoTDkFudGhyb3BpYywgUEJDMSkwJwYDVQQDEyBBbnRocm9waWMgQ2xhdWRlIENvbnRlbnQgU2lnbmluZzBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABJh6CmvLUBgFFNU0vUKlOVtE6djd17L5SuwX0LemFisBM3dkd/3cyjxFA3Qo5S46fX0/ihY0VZ7mfb9KF703t5OjWDBWMA4GA1UdDwEB/wQEAwIHgDAVBgNVHSUEDjAMBgorBgEEAYPoXgIBMAwGA1UdEwEB/wQCMAAwHwYDVR0jBBgwFoAUzlHiBIFOZFsj+OPEz5o+nMHXXMIwCgYIKoZIzj0EAwMDZwAwZAIwMXMdFJ4BetLLVY7ORuE9noqbbAZOZn/aArXyTwFAZfKrPzxF2vPoJNf1+UCdg1XGAjBwX1zd9WGqYkqmL5SFqw1QySjr1zJfpJM9+1rdDwSPLMOPOjKuiXjoU/pUUeG9RwmhY3BhZFkNngAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAPZYQLwcCC6iczBYRw7N5n5n2cbtKLLWwrhvvSW//zNVqbAOxQDkzxfWaE2XED+q8hvkH8rbN/EyVuiaQFDx7YM5NVk=</c2pa:manifest></metadata>
  <defs>
    <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto">
      <path d="M0 0 L10 5 L0 10 z" fill="#333"/>
    </marker>
  </defs>
  <style>
    .box { fill:#fff; stroke:#444; stroke-width:1.5; }
    .grp { fill:none; stroke:#888; stroke-width:1.3; stroke-dasharray:8 5; }
    .t  { font-size:14px; font-weight:bold; fill:#222; text-anchor:middle; }
    .s  { font-size:11px; fill:#555; text-anchor:middle; }
    .l  { font-size:12px; fill:#333; }
    .h  { font-size:12px; font-weight:bold; fill:#333; }
    .a  { stroke:#333; stroke-width:1.6; fill:none; marker-end:url(#arr); }
    .d  { stroke:#777; stroke-width:1.4; fill:none; stroke-dasharray:5 4; marker-end:url(#arr); }
    .n  { fill:#333; }
    .nt { font-size:11px; font-weight:bold; fill:#fff; text-anchor:middle; }
  </style>

  <rect width="1700" height="1090" fill="#fff"/>

  <!-- TOP ROW -->
  <rect class="box" x="40" y="24" width="150" height="60" rx="6"/>
  <text class="t" x="115" y="50">Developer</text>
  <text class="s" x="115" y="69">WSL + VS Code</text>

  <rect class="box" x="260" y="24" width="250" height="60" rx="6"/>
  <text class="t" x="385" y="50">GitHub repository</text>
  <text class="s" x="385" y="69">code, Terraform, manifests</text>

  <rect class="box" x="730" y="24" width="180" height="60" rx="6"/>
  <text class="t" x="820" y="50">Users</text>
  <text class="s" x="820" y="69">web browser</text>

  <rect class="box" x="1230" y="24" width="230" height="60" rx="6"/>
  <text class="t" x="1345" y="50">Terraform</text>
  <text class="s" x="1345" y="69">Jenkins-Server-TF + EKS-TF</text>

  <!-- AWS CLOUD -->
  <rect class="grp" x="20" y="110" width="1660" height="930" rx="10"/>
  <text class="h" x="40" y="136" style="font-size:15px">AWS Cloud | ap-south-1 (Mumbai)</text>

  <!-- Default VPC -->
  <rect class="grp" x="40" y="150" width="520" height="520" rx="8"/>
  <text class="h" x="60" y="171">Default VPC (Jenkins-Server-TF)</text>

  <rect class="box" x="60" y="185" width="480" height="470" rx="6"/>
  <text class="h" x="80" y="210" style="font-size:13px">Jenkins server | EC2 t3.large, Ubuntu 22.04</text>

  <g class="l">
    <rect class="box" x="70" y="235" width="300" height="44" rx="4"/><text x="82" y="262">1  Checkout from GitHub</text>
    <rect class="box" x="70" y="291" width="300" height="44" rx="4"/><text x="82" y="318">2  SonarQube analysis + Quality Gate</text>
    <rect class="box" x="70" y="347" width="300" height="44" rx="4"/><text x="82" y="374">3  npm install</text>
    <rect class="box" x="70" y="403" width="300" height="44" rx="4"/><text x="82" y="430">4  Trivy file scan (Dep-Check optional)</text>
    <rect class="box" x="70" y="459" width="300" height="44" rx="4"/><text x="82" y="486">5  Docker build</text>
    <rect class="box" x="70" y="515" width="300" height="44" rx="4"/><text x="82" y="542">6  Push to ECR + Trivy image scan</text>
    <rect class="box" x="70" y="571" width="300" height="44" rx="4"/><text x="82" y="598">7  Update image tag, git push</text>
  </g>
  <g class="a">
    <line x1="220" y1="279" x2="220" y2="291"/>
    <line x1="220" y1="335" x2="220" y2="347"/>
    <line x1="220" y1="391" x2="220" y2="403"/>
    <line x1="220" y1="447" x2="220" y2="459"/>
    <line x1="220" y1="503" x2="220" y2="515"/>
    <line x1="220" y1="559" x2="220" y2="571"/>
  </g>

  <!-- SonarQube + Trivy -->
  <rect class="box" x="400" y="285" width="130" height="56" rx="6"/>
  <text class="t" x="465" y="310" style="font-size:12px">SonarQube 9.9</text>
  <text class="s" x="465" y="327" style="font-size:10px">Docker, port 9000</text>
  <line class="d" x1="370" y1="313" x2="400" y2="313"/>

  <rect class="box" x="400" y="400" width="130" height="56" rx="6"/>
  <text class="t" x="465" y="425" style="font-size:12px">Trivy</text>
  <text class="s" x="465" y="442" style="font-size:10px">files + images</text>
  <line class="d" x1="370" y1="425" x2="400" y2="425"/>

  <!-- ECR -->
  <rect class="box" x="40" y="700" width="520" height="90" rx="6"/>
  <text class="t" x="300" y="735">Amazon ECR</text>
  <text class="s" x="300" y="758" style="font-size:12px">private repositories: frontend, backend</text>
  <text class="s" x="300" y="776">image tag = Jenkins build number</text>

  <!-- Delivery flow -->
  <rect class="box" x="40" y="820" width="520" height="200" rx="6"/>
  <text class="h" x="60" y="846" style="font-size:13px">Delivery flow</text>
  <g class="l">
    <text x="60" y="870">1  Developer pushes code to GitHub</text>
    <text x="60" y="891">2  Jenkins checks out the repo and runs the pipeline</text>
    <text x="60" y="912">3  Image is built, scanned and pushed to ECR</text>
    <text x="60" y="933">4  Pipeline commits the new image tag to GitHub</text>
    <text x="60" y="954">5  ArgoCD detects the commit and syncs the cluster</text>
    <text x="60" y="975">6  Nodes pull the new image from ECR</text>
    <text x="60" y="996">7  Users reach the app through the load balancer</text>
  </g>

  <!-- App VPC -->
  <rect class="grp" x="640" y="150" width="1020" height="860" rx="8"/>
  <text class="h" x="1000" y="171">VPC three-tier-eks-vpc  10.1.0.0/16  (EKS-TF)</text>

  <!-- Public subnets -->
  <rect class="grp" x="660" y="190" width="980" height="110" rx="6"/>
  <text class="h" x="1000" y="212" style="font-size:11px">Public subnets (2 AZs)</text>
  <rect class="box" x="700" y="225" width="240" height="56" rx="6"/>
  <text class="t" x="820" y="249" style="font-size:13px">Application Load Balancer</text>
  <text class="s" x="820" y="267" style="font-size:10px">internet-facing, Ingress class alb</text>
  <rect class="box" x="1000" y="225" width="200" height="56" rx="6"/>
  <text class="t" x="1100" y="249" style="font-size:12px">NAT gateway</text>
  <text class="s" x="1100" y="267" style="font-size:10px">single, shared (cost saving)</text>
  <rect class="box" x="1260" y="225" width="170" height="56" rx="6"/>
  <text class="t" x="1345" y="258" style="font-size:12px">Internet gateway</text>

  <!-- EKS cluster -->
  <rect class="grp" x="660" y="330" width="980" height="650" rx="6"/>
  <text class="h" x="680" y="968">Amazon EKS 1.34 | three-tier-eks | private subnets | 3 x m7i-flex.large (Amazon Linux 2023)</text>

  <!-- namespace three-tier -->
  <rect class="grp" x="680" y="380" width="560" height="330" rx="6"/>
  <text class="h" x="1230" y="402" text-anchor="end">namespace: three-tier</text>

  <rect class="box" x="700" y="430" width="160" height="90" rx="6"/>
  <text class="t" x="780" y="460">frontend</text>
  <text class="s" x="780" y="479">React, port 3000</text>
  <text class="s" x="780" y="497">2 replicas</text>

  <rect class="box" x="890" y="430" width="160" height="90" rx="6"/>
  <text class="t" x="970" y="460">backend</text>
  <text class="s" x="970" y="479">Node/Express, 3500</text>
  <text class="s" x="970" y="497">3 replicas</text>

  <rect class="box" x="1080" y="430" width="140" height="90" rx="6"/>
  <text class="t" x="1150" y="460">MongoDB</text>
  <text class="s" x="1150" y="479">version 4.4.6</text>
  <text class="s" x="1150" y="497">1 replica</text>

  <rect class="box" x="890" y="560" width="160" height="66" rx="6"/>
  <text class="t" x="970" y="581" style="font-size:11px">Secret mongo-sec</text>
  <text class="s" x="970" y="598" style="font-size:10px">created with kubectl,</text>
  <text class="s" x="970" y="612" style="font-size:10px">not stored in Git</text>

  <rect class="box" x="1080" y="560" width="140" height="66" rx="6"/>
  <text class="t" x="1150" y="586" style="font-size:12px">EBS gp3 volume</text>
  <text class="s" x="1150" y="604">2 GiB PVC</text>

  <!-- namespace argocd -->
  <rect class="box" x="1260" y="380" width="360" height="120" rx="6"/>
  <text class="t" x="1440" y="408" style="font-size:13px">namespace: argocd</text>
  <text class="h" x="1440" y="432" text-anchor="middle">ArgoCD</text>
  <text class="s" x="1440" y="451">Application: three-tier</text>
  <text class="s" x="1440" y="469">auto-sync, prune, self-heal</text>

  <!-- namespace monitoring -->
  <rect class="box" x="1260" y="530" width="360" height="180" rx="6"/>
  <text class="t" x="1440" y="558" style="font-size:13px">namespace: monitoring</text>
  <text class="h" x="1440" y="586" text-anchor="middle">Prometheus + Grafana</text>
  <text class="s" x="1440" y="605">kube-prometheus-stack (Helm)</text>
  <text class="s" x="1440" y="630">Alert: BackendPodsUnavailable</text>
  <text class="s" x="1440" y="655">UI through kubectl port-forward</text>
  <text class="s" x="1440" y="680">dashboards: pods, nodes, namespace</text>

  <!-- kube-system -->
  <rect class="grp" x="680" y="740" width="940" height="110" rx="6"/>
  <text class="h" x="700" y="764">namespace: kube-system</text>
  <text class="l" x="700" y="792">AWS Load Balancer Controller (Helm, IAM role for service account)</text>
  <text class="l" x="700" y="814">EBS CSI driver (storage)   |   CoreDNS   |   kube-proxy   |   VPC CNI</text>
  <text class="l" x="700" y="836">Managed node group: min 2, max 4 nodes</text>

  <!-- access note -->
  <rect class="box" x="680" y="870" width="940" height="60" rx="6"/>
  <text class="l" x="700" y="896">Operator access: kubectl port-forward to ArgoCD, Grafana and Prometheus (no public endpoints).</text>
  <text class="l" x="700" y="916">Jenkins and SonarQube are reachable only from the author's IP through the security group.</text>

  <!-- ARROWS -->
  <g class="a">
    <line x1="190" y1="54" x2="260" y2="54"/>
    <line x1="300" y1="84" x2="300" y2="185"/>
    <line x1="300" y1="655" x2="300" y2="700"/>
    <path d="M370 593 L585 593 L585 54 L510 54"/>
    <path d="M1500 380 L1500 97 L480 97 L480 84"/>
    <line x1="560" y1="745" x2="660" y2="745"/>
    <line x1="820" y1="84" x2="820" y2="225"/>
    <line x1="760" y1="281" x2="780" y2="430"/>
    <line x1="900" y1="281" x2="970" y2="430"/>
    <line x1="1050" y1="475" x2="1080" y2="475"/>
    <line x1="1150" y1="520" x2="1150" y2="560"/>
  </g>
  <g class="d">
    <line x1="1345" y1="84" x2="1345" y2="150"/>
    <line x1="970" y1="560" x2="970" y2="520"/>
    <line x1="1260" y1="440" x2="1240" y2="440"/>
    <line x1="1260" y1="620" x2="1240" y2="620"/>
  </g>

  <!-- arrow labels -->
  <text class="l" x="765" y="360" text-anchor="end" style="font-size:11px">/</text>
  <text class="l" x="960" y="360" style="font-size:11px">/api</text>
  <text class="l" x="1355" y="125" style="font-size:10px">provisions VPC, EKS, nodes, Jenkins server</text>
  <text class="l" x="1005" y="90" text-anchor="middle" style="font-size:10px">polls repo</text>
  <text class="l" x="575" y="330" text-anchor="middle" transform="rotate(-90 575 330)" style="font-size:10px">new image tag</text>

  <!-- step markers -->
  <g>
    <circle class="n" cx="225" cy="54" r="10"/><text class="nt" x="225" y="58">1</text>
    <circle class="n" cx="320" cy="130" r="10"/><text class="nt" x="320" y="134">2</text>
    <circle class="n" cx="320" cy="677" r="10"/><text class="nt" x="320" y="681">3</text>
    <circle class="n" cx="585" cy="200" r="10"/><text class="nt" x="585" y="204">4</text>
    <circle class="n" cx="1100" cy="97" r="10"/><text class="nt" x="1100" y="101">5</text>
    <circle class="n" cx="610" cy="722" r="10"/><text class="nt" x="610" y="726">6</text>
    <circle class="n" cx="842" cy="150" r="10"/><text class="nt" x="842" y="154">7</text>
  </g>

  <!-- title -->
  <text class="t" x="850" y="1068" style="font-size:16px">Three-tier DevSecOps on AWS EKS | Terraform, Jenkins, SonarQube, Trivy, ECR, ArgoCD, Prometheus, Grafana</text>
</svg>

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
<img width="888" height="327" alt="Screenshot 2026-10-28 124141" src="https://github.com/user-attachments/assets/574e82ae-74dd-415d-8a17-a87667fb954a" />


- SonarQube project dashboards
<img width="872" height="362" alt="Screenshot 2026-10-28 124232" src="https://github.com/user-attachments/assets/665e4db7-ed5b-411f-8f4d-950f0916df60" />


- `kubectl get nodes` and `kubectl get pods,svc,pvc,ingress -n three-tier`
<img width="583" height="101" alt="Screenshot 2026-10-28 124632" src="https://github.com/user-attachments/assets/0417e4d1-6f12-4d47-a547-34d64db7f60e" />
<img width="593" height="136" alt="Screenshot 2026-10-28 124644" src="https://github.com/user-attachments/assets/c69fd553-e544-4171-8601-7da860fcb212" />

- ArgoCD 
<img width="715" height="407" alt="Screenshot 2026-10-28 124545" src="https://github.com/user-attachments/assets/f2825a4b-5b2a-43d3-a4e1-4edc06d0bf1b" />

- Grafana dashboard 
<img width="643" height="463" alt="Screenshot 2026-10-28 124959" src="https://github.com/user-attachments/assets/a0b37f7c-427f-4cc3-97b2-117a3ddf6d3b" />


## Author

Ishika Sharma, [github.com/ishikasharma05](https://github.com/ishikasharma05)
