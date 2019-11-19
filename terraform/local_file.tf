
resource "local_file" "efs_provisioner_file" {
    content     = <<EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: efs-service-account
  namespace: kube-system
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: efs-provisioner
  namespace: kube-system
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-efs-provisioner
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: efs-service-account
    namespace: kube-system
roleRef:
  kind: ClusterRole
  name: efs-provisioner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-efs-provisioner
  namespace: kube-system
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-efs-provisioner
  namespace: kube-system
subjects:
  - kind: ServiceAccount
    name: efs-service-account
    # replace with namespace where provisioner is deployed
    namespace: kube-system
roleRef:
  kind: Role
  name: leader-locking-efs-provisioner
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: efs-provisioner
  namespace: kube-system
data:
  file.system.id: ${element(split(".", aws_efs_file_system.sre-challenge-efs.dns_name),0)}
  aws.region: eu-west-1
  provisioner.name: example.com/aws-efs
---
kind: Deployment
apiVersion: extensions/v1beta1
metadata:
  name: efs-provisioner
  namespace: kube-system
spec:
  replicas: 1
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: efs-provisioner
    spec:
      serviceAccount: efs-service-account
      containers:
        - name: efs-provisioner
          image: quay.io/external_storage/efs-provisioner:latest
          env:
            - name: FILE_SYSTEM_ID
              valueFrom:
                configMapKeyRef:
                  name: efs-provisioner
                  key: file.system.id
            - name: AWS_REGION
              valueFrom:
                configMapKeyRef:
                  name: efs-provisioner
                  key: aws.region
            - name: PROVISIONER_NAME
              valueFrom:
                configMapKeyRef:
                  name: efs-provisioner
                  key: provisioner.name
          volumeMounts:
            - name: pv-volume
              mountPath: /persistentvolumes
      volumes:
        - name: pv-volume
          nfs:
            server: ${aws_efs_file_system.sre-challenge-efs.dns_name}
            path: /
---
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: aws-efs
provisioner: example.com/aws-efs
reclaimPolicy: Retain

EOF
    filename = "${path.module}./artifacts/efs-provisioner.yaml"
}

resource "null_resource" "eks_init" {
  provisioner "local-exec" {
    command = "echo ${module.sre-challenge-cluster.cluster_arn}.${module.db.this_db_instance_address}"
  }
  provisioner "local-exec" {
    command = "aws eks --region eu-west-1 update-kubeconfig --name sre-challenge-cluster"
  }
}

resource "local_file" "db_config_map" {
    content     = <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: db-config-map
  namespace: default
data:
  DB_HOST: "${module.db.this_db_instance_address}"
  DB_NAME: "${module.db.this_db_instance_name}"
  DB_USER: "${module.db.this_db_instance_username}"
  DB_PASSWORD: "${module.db.this_db_instance_password}"
  EOF
  filename = "${path.module}./artifacts/db-config-map.yaml"
}
