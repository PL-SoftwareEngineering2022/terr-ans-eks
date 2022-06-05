This terrafrom configuration creates an `EKS cluster with Fargate.`

- install kubectl on Windows using choco:
`choco install kubernetes-cli` or `curl -o kubectl.exe https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/windows/amd64/kubectl.exe`
 ### Note
*You must use a kubectl version that is within one minor version difference of your Amazon EKS cluster control plane. For example, a 1.21 kubectl client works with Kubernetes 1.20, 1.21 and 1.22 clusters.*

- to check it was installed: 

- To generate a `~/.kube/config`, run the folloing command:
    -  `aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}`
        - `aws eks update-kubeconfig --region us-west-1 --name cali-EKS-cluster`
            - *To remove this file, run:* `rm -rf ~/.kube/config`

- run kubectl commands
    - `kubectl get all`
    - `kubectl get pod -n fargate-node`
    - `kubectl get ns`
    - `kubectl get pods`
    - ``