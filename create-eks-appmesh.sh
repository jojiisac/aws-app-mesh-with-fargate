

#export ACCOUNT_ID="<your_account_Id>"

export CLUSTER_NAME=test-cluster
export AWS_REGION=ap-south-1

eksctl create cluster --name $CLUSTER_NAME --region ap-south-1  --fargate 
aws eks --region ap-south-1 update-kubeconfig --name $CLUSTER_NAME



 eksctl create fargateprofile -f ./clusterconfig.yaml

###  installing app mesh  

# Create the namespace
kubectl create ns appmesh-system
kubectl create ns prod 
kubectl create namespace prodcatalog-ns




# Download the IAM policy for AWS App Mesh Kubernetes Controller
#    curl -o controller-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/controller-iam-policy.json

# Create an IAM policy called AWSAppMeshK8sControllerIAMPolicy
aws iam create-policy \
    --policy-name AWSAppMeshK8sControllerIAMPolicy \
    --policy-document file://controller-iam-policy.json




# Create your OIDC identity provider for the cluster
eksctl utils associate-iam-oidc-provider --region=$AWS_REGION \
  --cluster $CLUSTER_NAME  \
  --approve


# Create an IAM role for the appmesh-controller service account
eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
    --namespace appmesh-system \
    --name appmesh-controller \
    --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSAppMeshK8sControllerIAMPolicy  \
    --override-existing-serviceaccounts \
    --approve



eksctl create fargateprofile --cluster $CLUSTER_NAME --namespace appmesh-system



# Download the IAM policy document for the Envoy proxies
# --curl -o envoy-iam-policy.json https://raw.githubusercontent.com/aws/aws-app-mesh-controller-for-k8s/master/config/iam/envoy-iam-policy.json

# Create an IAM policy for the proxies from the policy document
aws iam create-policy \
    --policy-name AWSAppMeshEnvoySidecarIAMPolicy \
    --policy-document file://envoy-iam-policy.json

# Create an IAM role and service account for the application namespace
eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --namespace prod \
  --name default \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/AWSAppMeshEnvoySidecarIAMPolicy  \
  --override-existing-serviceaccounts \
  --approve




#  install app mesh
# Install the App Mesh CRDs
kubectl apply -k "https://github.com/aws/eks-charts/stable/appmesh-controller/crds?ref=master"
helm repo add eks https://aws.github.io/eks-charts

helm upgrade -i appmesh-controller eks/appmesh-controller \
    --namespace appmesh-system \
    --set region=$AWS_REGION \
    --set serviceAccount.create=false \
    --set serviceAccount.name=appmesh-controller






 aws iam create-policy \
    --policy-name ProdEnvoyNamespaceIAMPolicy \
    --policy-document  file://./envoy-iam-policy.json 

eksctl create iamserviceaccount --cluster $CLUSTER_NAME \
  --namespace prodcatalog-ns \
  --name prodcatalog-envoy-proxies \
  --attach-policy-arn arn:aws:iam::$ACCOUNT_ID:policy/ProdEnvoyNamespaceIAMPolicy \
  --override-existing-serviceaccounts \
  --approve 


eksctl create fargateprofile -f ./clusterconfig.yaml




## deleting 
# eksctl delete fargateprofile --cluster test-cluster  fp-default

# eksctl delete fargateprofile --cluster test-cluster  fargate-productcatalog
# eksctl delete fargateprofile --cluster test-cluster    appmesh-system

#  eksctl delete cluster --name test-cluster --region ap-south-1 

### PENDING OBSERVABILITY 


#// lb 

curl -o alb_iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/release-2.4/docs/install/iam_policy.json 

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://alb_iam_policy.json



eksctl create iamserviceaccount \
  --cluster $CLUSTER_NAME \
  --namespace kube-system \
  --name aws-load-balancer-controller \
  --attach-policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
  --override-existing-serviceaccounts \
  --approve



kubectl get sa aws-load-balancer-controller -n kube-system

kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"


export VPC_ID=$(aws eks describe-cluster \
                --name $CLUSTER_NAME \
                --query "cluster.resourcesVpcConfig.vpcId" \
                --output text)
echo $VPC_ID

export LBC_VERSION="v2.4.1"
export LBC_CHART_VERSION="1.4.1"

helm upgrade -i aws-load-balancer-controller \
    eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName="${CLUSTER_NAME}" \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller \
    --set image.tag="${LBC_VERSION}" \
    --set region=${AWS_REGION} \
    --set vpcId=${VPC_ID} \
    --version="${LBC_CHART_VERSION}"