pkill -9 kubectl port-forward
kubectl delete -f app-deployment.yaml
kubectl delete statefulset cockroachdb
kubectl delete pod cockroachdb-client-secure
kubectl delete service cockroachdb-public
kubectl delete service cockroachdb
kubectl delete serviceaccount cockroachdb
kubectl delete role cockroachdb
kubectl delete rolebinding cockroachdb
kubectl delete poddisruptionbudgets.policy cockroachdb-budget
sleep 5
kubectl get statefulset,pods,service,serviceaccount,role,rolebinding
