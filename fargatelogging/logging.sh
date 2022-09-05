  # create  ns 
  kubectl apply -f ./namespace.yml
  # create CM to enable logging 
  kubectl apply -f ./cm.yml
  

# craete policy 
  aws iam create-policy --policy-name eks-fargate-logging-policy --policy-document file://permissions.json


  # attachpolicy to pod excecuion role 
  aws iam attach-role-policy \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/eks-fargate-logging-policy \
  --role-name eksctl-test-cluster-cluste-FargatePodExecutionRole-1R24VH5IEDTDK

kubectl  apply -f log-cerating-app.yml 