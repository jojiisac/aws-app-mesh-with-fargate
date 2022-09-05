  # create  ns 
  kubectl apply -f ./namespace.yml
  # create CM to enable logging 
  kubectl apply -f ./cm.yml
  

# craete policy 
  aws iam create-policy --policy-name eks-fargate-logging-policy --policy-document file://permissions.json


  # attachpolicy to pod excecuion role 
  ## NOTE : --- role name will change each time, get it by the follwing script 
  aws iam list-roles | grep FargatePodExecutionRole


  aws iam attach-role-policy \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/eks-fargate-logging-policy \
  --role-name eksctl-test-cluster-cluste-FargatePodExecutionRole-1TESIKFOGY8QA
  
kubectl  apply -f log-creating-app.yml

