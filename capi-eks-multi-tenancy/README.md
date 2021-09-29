# Cluster-api eks multi-tenancy demo

This demo will install CAPI+CAPA on a KinD cluster. 
It starts CAPA without any valid credentials, and it creates a static identity provider from the given aws key. 

## Prerequisites
- Install `kind`: 
   https://kind.sigs.k8s.io/docs/user/quick-start/ 
- Install `clusterctl`
   https://cluster-api-aws.sigs.k8s.io/getting-started.html 
   ```
   curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v0.4.3/clusterctl-darwin-amd64 -o clusterctl
   ```
- Install `clusterawsadm`
   https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases
- setup some env vars & create cloudformation
   ```
   export AWS_REGION=us-east-1 
   export AWS_ACCESS_KEY_ID=<your-access-key>
   export AWS_SECRET_ACCESS_KEY=<your-secret-access-key>
   export AWS_SSH_KEY_NAME=<your-ssh-key>

   # create cloudformation stack for roles will be used in this demo, you only need to do it once
   clusterawsadm bootstrap iam create-cloudformation-stack --config bootstrap-config.yaml

   # this credential is just created for `clusterctl init`, and it will be removed from the capa deployment
   export AWS_B64ENCODED_CREDENTIALS=$(clusterawsadm bootstrap credentials encode-as-profile)
   ```

## Demo
run the following command, and watch magic happens:
```
./demo
```

## Cleanup
run the following after demo to delete the eks cluster:
```
kubectl delete -f capi-eks-quickstart.yaml
```

run the following to delete the kind cluster after the eks is deleted:
```
kind delete cluster --name capi-eks
```

run the following to remove the cloudformation created (not recommanded if you want to run the demo again):
```
clusterawsadm bootstrap iam delete-cloudformation-stack --config bootstrap-config.yaml
```


## Notes
- All secrets for credential have to be in the same namespace as capa controller.
- Examples of multitenancy from https://cluster-api-aws.sigs.k8s.io/topics/multitenancy.html are in v1alpha3, so some fields are out-dated already. (e.g. secretRef of AWSClusterStaticIdentity is now a string). Also awsmachinepool with scaling empty will hit an nil bug, that's why we didn't use generated yaml directly.
- Did't investigated if `EKSEnableIAM=true,EKSAllowAddRoles=true` will work without cloudformation.