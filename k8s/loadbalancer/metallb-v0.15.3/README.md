# MetalLB Installation on Bare-Metal Kubernetes

This document describes how to install and configure **MetalLB** on a **bare-metal / on‑premises Kubernetes cluster** running on **Ubuntu 24.04** with **Kubernetes v1.33**.

The instructions assume you already have a **working Kubernetes cluster** (control plane + workers) using **containerd** and a supported **CNI plugin** (for example, **Cilium**).

---

## 1. Background

On cloud providers, Kubernetes Services of type `LoadBalancer` are backed by a cloud‑native L4 load balancer. On bare‑metal or on‑premises clusters, this functionality does **not exist by default**, resulting in:

```text
EXTERNAL-IP   <pending>
```

**MetalLB** fills this gap by providing a **software implementation of a network load balancer** that integrates natively with Kubernetes Services.

MetalLB supports the following operating modes:

- **Layer 2 (ARP / NDP)** – simple, no external dependencies
- **BGP** – scalable, production‑grade
- **FRR / FRR‑K8s** – advanced BGP integrations

For most small to medium bare‑metal clusters, **Layer 2 mode** is sufficient and is the focus of this guide.

---

## 2. Prerequisites

Ensure the following requirements are met before installing MetalLB:

- Kubernetes (**v1.33** used in this guide)
- A working CNI plugin (Cilium, Calico, Flannel, etc.)
- Cluster nodes are on the **same L2 network** (for Layer 2 mode)
- A **free IPv4 address range** on your local network
- The chosen IP range is **excluded from DHCP** to avoid conflicts

> Note: MetalLB generally does **not** work on managed cloud load balancer environments.

---

## 3. kube-proxy Configuration (Strict ARP)

If your cluster uses **kube‑proxy in IPVS mode**, you must enable **strict ARP**.

Check and edit the kube‑proxy ConfigMap:

```bash
kubectl edit configmap kube-proxy -n kube-system
```

Ensure the configuration contains:

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

Apply automatically (optional):

```bash
# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

> If you are using **kube-router**, this step is not required.

---

## 4. Install MetalLB

MetalLB can be installed using **manifests**, **Kustomize**, or **Helm**. This guide uses the **official manifest**.

### 4.1 Install Using Official Manifest

```bash
# Deploy MetalLB (specific version)
kubectl apply -f k8s/loadbalancer/metallb-v0.15.3/01-metallb-native.yaml

# If you want to deploy MetalLB using the latest version
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/main/config/manifests/metallb-native.yaml
```

This deploys MetalLB into the `metallb-system` namespace and creates:

- `controller` Deployment
- `speaker` DaemonSet
- Required RBAC resources

Verify installation:

```bash
kubectl get pods -n metallb-system
```

Expected output:

```text
controller-xxxxx   Running
speaker-xxxxx      Running
```

> The components will remain **idle** until MetalLB is configured.

---

## 5. Configure MetalLB (Layer 2 Mode)

MetalLB configuration is done using Kubernetes **CRDs** (not ConfigMaps in recent versions).

### 5.1 Define IP Address Pool

Create an IP pool using addresses available on your local network.

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: default-pool
  namespace: metallb-system
spec:
  addresses:
    - 192.168.1.240-192.168.1.250
```

Apply it:

```bash
kubectl apply -f ipaddresspool.yaml
```

### 5.2 Create Layer 2 Advertisement

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
    - default-pool
```

Apply it:

```bash
kubectl apply -f l2advertisement.yaml
```

> Ensure these IPs are **not managed by DHCP**.

---

## 6. Test MetalLB with a Sample Application

### 6.1 Deploy Test Application

```bash
kubectl create deployment hello-app \
  --image=gcr.io/google-samples/hello-app:1.0 \
  --replicas=3
```

Expose it using a LoadBalancer Service:

```bash
kubectl expose deployment hello-app \
  --type=LoadBalancer \
  --port=80 \
  --target-port=8080
```

### 6.2 Verify Service IP Assignment

```bash
kubectl get svc hello-app
```

Expected output:

```text
NAME        TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
hello-app  LoadBalancer   10.x.x.x         192.168.1.240   80:xxxxx/TCP
```

### 6.3 Test Access

```bash
curl http://192.168.1.240
```

Repeated requests should show different hostnames, indicating load balancing across pods.

---

## 7. Security Notes (Pod Security Admission)

For Kubernetes versions enforcing **Pod Security Admission**, label the namespace:

```bash
kubectl label namespace metallb-system \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged
```
