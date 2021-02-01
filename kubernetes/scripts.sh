kubeadm token create --print-join-command

kubectl taint nodes --all node-role.kubernetes.io/master-

kubectl get cs / kubectl get componentstatuses

kubectl -n kube-system get pods -o wide
kubectl run -it --rm --restart=Never --image=infoblox/dnstools:latest dnstools