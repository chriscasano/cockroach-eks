# Create CockroachDB StatefulSet
echo '*********************************************'
echo '***** Creating CockroachDB Stateful Set *****'
echo '*********************************************'

kubectl create -f cockroachdb-statefulset.yaml
kubectl create -f client.yaml
sleep 15
echo '************ Creation Status ****************'
kubectl get statefulset,secrets,pods,services

## Open Admin UI
read -p '*Press return to open Admin UI*' nothing

kubectl port-forward cockroachdb-0 8080 > /dev/null 2>&1 &
sleep 5
/usr/bin/open -a "/Applications/Google Chrome.app" 'http://127.0.0.1:8080'

## Deploy Flask App
read -p '*Press return to deploy the Flask app*' nothing

kubectl apply -f app-deployment.yaml
sleep 5
kubectl get pods -l app=flask

kubectl port-forward `kubectl get pods -l app=flask | grep appdeploy | head -1 | awk '{print $1}'` 5000 > /dev/null 2>&1 &
/usr/bin/open -a "/Applications/Google Chrome.app" 'http://127.0.0.1:5000'

## Show Resilience
read -p '*Press return to kill a app and db node*' nothing

kubectl delete pod cockroachdb-2
#kubectl delete pod `kubectl get pods -l app=flask | grep appdeploy | tail -1 | awk '{print $1}'`

echo '***************************************************'
