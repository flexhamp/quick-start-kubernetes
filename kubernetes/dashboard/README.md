Creating a Service Account We are creating Service Account with name admin-user in namespace kubernetes-dashboard first.

```shell
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
name: admin-user
namespace: kubernetes-dashboard
EOF
```

Creating a ClusterRoleBinding In most cases after provisioning cluster using kops, kubeadm or any other popular tool,
the ClusterRole cluster-admin already exists in the cluster. We can use it and create only ClusterRoleBinding for our
ServiceAccount. If it does not exist then you need to create this role first and grant required privileges manually.

```shell
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

Getting a Bearer Token Now we need to find token we can use to log in. Execute following command:

```shell
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```