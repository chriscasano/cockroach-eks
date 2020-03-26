# Webinar: How to Deploy CockroachDB on EKS with StatefulSets

__*What are we doing here?*__ We are deploying a simple Flask application that is powered by an underlying database called CockroachDB.  We are deploying this on Amazon's Elastic Kubernetes Service (EKS) so that you can learn how to deploy modern applications that work on a consistent database and efficient, flexible infrastructure.

__*Why is this important?*__ For modernizing your skill set so you can develop modern applications for yourself, for someone else, your business, your charity, your company, etc.

## Prepare

1) Sign up for [Amazon Web Services](https://aws.amazon.com/) account if you don't have one.  You can do this with GKE and other flavors of K8S but the instructions below will have to be adjusted.

2) [Install helm](https://helm.sh/docs/intro/install/) - This is a package manger for deploying software on Kubernetes.

I have a mac so [homebrew](https://brew.sh/) works the best...

`brew install helm`

`helm repo add stable https://kubernetes-charts.storage.googleapis.com`

`helm repo update`

3) [Install aws cli and eksctl](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)

Make sure [AWS-IAM Authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html) and kubectl is installed too.  The eksctl installer should install these things.  If not...

`brew install aws-iam-authenticator`

`brew install kubectl`

## Deploy an EKS Cluster
You can utilize Cockroach Labs [documentation](https://www.cockroachlabs.com/docs/v19.2/orchestrate-cockroachdb-with-kubernetes-insecure.html#hosted-eks) as well for creating an EKS cluster with the proper resource settings.

#### Create an EKS Cluster

Update the EKS_CLUSTER_NAME and EKS_PUBLIC_KEY variables in the script below.

  `./create_eks.sh`

## Deploy CockroachDB

#### Install Cockroach (Insecure)

While your EKS cluster is being created, you can start another terminal session and prepare Helm.

`helm template stable/cockroachdb --output-dir ./`

Ensure your template/values.yaml file with the following params

- statefulset.resources.limits.memory: "8Gi"  
- statefulset.resources.requests.memory: "8Gi"  
- conf.cache: "2Gi"  
- conf.max-sql-memory: "2Gi"


`helm install my-release --values ./cockroachdb/templates/values.yaml stable/cockroachdb`

#### Install Cockroach (Secure with Custom CA) - Manual Config

[Primary Documentation]( https://www.cockroachlabs.com/docs/v19.2/orchestrate-cockroachdb-with-kubernetes.html#step-2-start-cockroachdb)

Unfortunately you can not do a Helm install for a secure EKS install since EKS doesn't support certificate signing requests.

##### Get a local copy of the StatefulSet config file, or use the one in this repo.

`curl -O https://raw.githubusercontent.com/cockroachdb/cockroach/master/cloud/kubernetes/bring-your-own-certs/cockroachdb-statefulset.yaml`

##### Setup your certs and add them as EKS secrets

`mkdir certs`

`mkdir my-safe-directory`

`cockroach cert create-ca --certs-dir=certs --ca-key=my-safe-directory/ca.key`

`cockroach cert create-client root --certs-dir=certs --ca-key=my-safe-directory/ca.key`

`cockroach cert create-client maxroach --certs-dir=certs --ca-key=my-safe-directory/ca.key`

`kubectl create secret generic cockroachdb.client.root --from-file=certs`

`kubectl create secret generic cockroachdb.client.maxroach --from-file=certs`

`cockroach cert create-node --certs-dir=certs --ca-key=my-safe-directory/ca.key localhost 127.0.0.1 cockroachdb-public cockroachdb-public.default cockroachdb-public.default.svc.cluster.local *.cockroachdb *.cockroachdb.default *.cockroachdb.default.svc.cluster.local`

`kubectl create secret generic cockroachdb.node --from-file=certs`

`kubectl create -f cockroachdb-statefulset.yaml`

##### Initialize cluster

`kubectl exec -it cockroachdb-0 -- /cockroach/cockroach init --certs-dir=/cockroach/cockroach-certs`

##### Check Admin UI & Forward UI Port

`kubectl port-forward cockroachdb-0 8080`

If using Chrome and you get block by cert / privacy warning; type in "thisisunsafe".  Or just use Safari and click thru.

##### Run SQL client / Create Database

Get the client config pod or just use the one local in this repo

`curl -O https://raw.githubusercontent.com/cockroachdb/cockroach/master/cloud/kubernetes/bring-your-own-certs/client.yaml`

`kubectl create -f client.yaml`

`kubectl exec -it cockroachdb-client-secure -- ./cockroach sql --certs-dir=/cockroach-certs --host=cockroachdb-public`

`CREATE USER maxroach WITH PASSWORD 'cockroach';`

`CREATE DATABASE todos;`

`USE todos;`

`GRANT ALL ON DATABASE todos TO maxroach;`

`CREATE TABLE todos (
    todo_id INT8 NOT NULL DEFAULT unique_rowid(),
    title VARCHAR(60) NULL,
    text VARCHAR NULL,
    done BOOL NULL,
    pub_date TIMESTAMP NULL,
    CONSTRAINT "primary" PRIMARY KEY (todo_id ASC),
    FAMILY "primary" (todo_id, title, text, done, pub_date)
  );`


## Deploy Flask application

[Primary Documentation](https://www.cockroachlabs.com/docs/cockroachcloud/v19.2/deploy-a-python-to-do-app-with-flask-kubernetes-and-cockroachcloud.html)

#### Setup Docker Hub (optional)

Only do this if you want to re-dockerize the Flask app.  Otherwise, you can pull it from my [Docker Hub repo](https://hub.docker.com/repository/docker/chriscasano/hello-app):

`cd hello-app`

`docker login`

`docker build hello-app .`

`docker push hello-app`

If you want to connect your EKS cluster to your Docker Hub account, you can use the following snippet to add Docker credentials into EKS.

`kubectl create secret generic dockercred --from-file=.dockerconfigjson=.docker/config.json --type=kubernetes.io/dockerconfigjson`

#### Run app

kubectl apply -f app-deployment.yaml

kubectl port-forward `kubectl get pods -l app=flask | grep appdeploy | head -1 | awk '{print $1}'` 5000


##### Kill a node

`kubectl delete pod cockroachdb-2`

## Self Driving Demonstration

Run apply_cockroach.sh to deploy the CockroachDB stateful set, Deploy the Flask app and do a Resilience test.

`./apply_cockroach.sh`

To remove all K8S applied resources, run the following script

`./remove_all.sh`

#### Handy Commands

Also, it's a pain doing kubectl for everything.  It's to put an alias such as 'k' for kubectl in your .bash_profile.

`aws sts get-caller-identity` - your current aws identity

`kubectl api-resources` - Show all K8S resources

`kubectl describe nodes` - Describe the nodes of your K8S cluster

`kubectl get pods` - Get pods

`kubectl delete pod <pod_name>` - Delete a pod

`kubectl exec -it <pod_name> -- /bin/bash` - Connect to a running container / pod

`kubectl get secrets` - get secrets


#### Errors / Issues
##### 1) If receiving the following error when creating an EKS cluster, go into CloudFormation UI and delete the stack mentioned below.  

  [✖]  creating CloudFormation stack "eksctl-chrisc-test-cluster": AlreadyExistsException: Stack [eksctl-chrisc-test-cluster] already exists
	  status code: 400, request id: c857aabf-2dea-4f54-b58a-da91c5a88c60

#### Documentation References

- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/#deleting-resources)
- [Cockroach EKS Deployment](https://www.cockroachlabs.com/docs/v19.2/orchestrate-cockroachdb-with-kubernetes-insecure.html#hosted-eks)
- [EKS Cluster Deletion Issues](https://aws.amazon.com/premiumsupport/knowledge-center/eks-delete-cluster-issues/) <-- This was useful more than once
