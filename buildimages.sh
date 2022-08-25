

cd /Users/stpc/joji/aws/eks-fargate/demo/
PROJECT_NAME=eks-app-mesh-demo
export APP_VERSION=1.0
for app in catalog_detail product_catalog frontend_node; do
  TARGET=jojiisacth/$app:$APP_VERSION
  docker build -t $TARGET apps/$app
  docker push $TARGET
done


