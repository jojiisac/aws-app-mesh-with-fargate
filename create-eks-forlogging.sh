

#export ACCOUNT_ID="<your_account_Id>"

export CLUSTER_NAME=test-cluster
export AWS_REGION=ap-south-1

eksctl create cluster --name $CLUSTER_NAME --region ap-south-1  --fargate 
aws eks --region ap-south-1 update-kubeconfig --name $CLUSTER_NAME



 eksctl create fargateprofile -f ./clusterconfig.yaml

###  installing app mesh  



# Download the IAM policy for AWS App Mesh Kubernetes Controller
#    curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json

# Create an IAM policy called AWSAppMeshK8sControllerIAMPolicy
aws iam create-policy \
    --policy-name AWSAppMeshK8sControllerIAMPolicy \
    --policy-document file://controller-iam-policy.json



eksctl create fargateprofile -f ./clusterconfig.yaml




## deleting 
# eksctl delete fargateprofile --cluster test-cluster  fp-default

# eksctl delete fargateprofile --cluster test-cluster  fargate-productcatalog
# eksctl delete fargateprofile --cluster test-cluster    appmesh-system

#  eksctl delete cluster --name test-cluster --region ap-south-1 

### PENDING OBSERVABILITY 


#// lb 
