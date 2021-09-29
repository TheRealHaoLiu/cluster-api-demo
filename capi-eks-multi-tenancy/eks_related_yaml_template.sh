function generate_static_provider_cr() {
cat <<EOF > capi-eks-static.yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    cluster.x-k8s.io/ns: "testlabel"
  name: test-eks
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha4
kind: AWSClusterStaticIdentity
metadata:
  name: "test-account"
spec:
  secretRef: "test-account-creds"
  allowedNamespaces:
    selector:
      matchLabels:
        cluster.x-k8s.io/ns: "testlabel"
---
apiVersion: v1
kind: Secret
metadata:
  name: "test-account-creds"
  namespace: capa-system
stringData:
 AccessKeyID: ${AWS_ACCESS_KEY_ID}
 SecretAccessKey: ${AWS_SECRET_ACCESS_KEY}
EOF
}

function generate_eks_yaml() {
cat <<EOF > capi-eks-quickstart.yaml
apiVersion: cluster.x-k8s.io/v1alpha4
kind: Cluster
metadata:
  name: capi-eks-${CLUSTER_NAME}
  namespace: test-eks
spec:
  clusterNetwork:
    pods:
      cidrBlocks:
      - 192.168.0.0/16
  controlPlaneRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1alpha4
    kind: AWSManagedControlPlane
    name: capi-eks-${CLUSTER_NAME}-control-plane
  infrastructureRef:
    apiVersion: controlplane.cluster.x-k8s.io/v1alpha4
    kind: AWSManagedControlPlane
    name: capi-eks-${CLUSTER_NAME}-control-plane
---
apiVersion: controlplane.cluster.x-k8s.io/v1alpha4
kind: AWSManagedControlPlane
metadata:
  name: capi-eks-${CLUSTER_NAME}-control-plane
  namespace: test-eks
spec:
  identityRef:
    kind: AWSClusterStaticIdentity
    name: test-account
  region: us-east-1
  sshKeyName: ${AWS_SSH_KEY_NAME}
  version: v1.21
---
apiVersion: cluster.x-k8s.io/v1alpha4
kind: MachinePool
metadata:
  name: capi-eks-${CLUSTER_NAME}-pool-0
  namespace: test-eks
spec:
  clusterName: capi-eks-${CLUSTER_NAME}
  replicas: 3
  template:
    spec:
      bootstrap:
        dataSecretName: ""
      clusterName: capi-eks-${CLUSTER_NAME}
      infrastructureRef:
        apiVersion: infrastructure.cluster.x-k8s.io/v1alpha4
        kind: AWSManagedMachinePool
        name: capi-eks-${CLUSTER_NAME}-pool-0
---
apiVersion: infrastructure.cluster.x-k8s.io/v1alpha4
kind: AWSManagedMachinePool
metadata:
  name: capi-eks-${CLUSTER_NAME}-pool-0
  namespace: test-eks
spec:
  scaling:
    minSize: 1
    maxSize: 3
  roleName: nodes.cluster-api-provider-aws.sigs.k8s.io
EOF
}