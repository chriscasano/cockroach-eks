export EKS_CLUSTER_NAME=chrisc-test
export EKS_PUBLIC_KEY=chrisc

eksctl create cluster --name $EKS_CLUSTER_NAME --nodegroup-name standard-workers --node-type m5.xlarge --nodes 3 --nodes-min 1 --nodes-max 4 --node-ami auto --ssh-access --ssh-public-key=$EKS_PUBLIC_KEY`
