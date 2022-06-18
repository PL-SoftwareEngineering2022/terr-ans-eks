This terrafrom configuration creates an `EKS cluster with Fargate.`

- install kubectl on Windows using `choco`:
`choco install kubernetes-cli` or 
- `curl -o kubectl.exe https://s3.us-west-2.amazonaws.com/amazon-eks/1.22.6/2022-03-09/bin/windows/amd64/kubectl.exe`
    - *Note*
        - *You must use a kubectl version that is within one minor version difference of your Amazon EKS cluster control plane. For example, a 1.21 kubectl client works with Kubernetes 1.20, 1.21 and 1.22 clusters.*
    - *Reference:*  
    https://docs.aws.amazon.com/eks/latest/userguide/install-kubectl.html
    https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.2/deploy/installation/
    

- To check if `kubectl` was successfully installed: 

-To generate a `~/.kube/config`, run the following command:
- `aws eks update-kubeconfig --region ${REGION} --name ${CLUSTER_NAME}`
    - `aws eks update-kubeconfig --region us-west-1 --name cali-EKS-cluster`
        - *To remove this file, run:* `rm -rf ~/.kube/config`

- **run kubectl commands**
    - `kubectl get all`
    - `kubectl get pod -n fargate-node`
    - `kubectl get ns`
    - `kubectl get pods`
    - `kubectl get ingress -n fargate-node`
    - `kubectl get svc`
    - `kubectl get sa`
    - `kubectl get ...`
- to destroy the resources, first delete the ingress:
    - `kubectl delete ingress -n fargate-node owncloud-lb`
        - then you can run a `terraform destroy -auto-approve`

- **Install a Jenkins Server:**
    - *Jenkins is dependent on Java*

https://www.digitalocean.com/community/tutorials/how-to-install-jenkins-on-ubuntu-18-04
- wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
- sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
- sudo apt update
- sudo apt install jenkins
- sudo systemctl start jenkins
- sudo systemctl status jenkins
- sudo ufw allow 8080
- sudo ufw status
- If the firewall is inactive, the following commands will allow OpenSSH and enable the firewall:

- sudo ufw allow OpenSSH
- sudo ufw enable

    - *Retrieve one time Jenkins password from the server*
- sudo cat /var/lib/jenkins/secrets/initialAdminPassword