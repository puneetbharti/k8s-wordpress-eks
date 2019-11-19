### Overview 
This project is a simple implimentation of wordpress on kubernetes, this will also  summarise the system-level architecture, tools used and the setup instructions.


### Tools Used
* Terraform (v0.12.12)
* Kubernetes (1.14)
* awscli (1.16.266)

### AWS Services Used
* EC2
* VPC
* EKS
* RDS
* EFS

### System Architecture 

#### High level diagram of two VPCs


![High Level Architecture Diagram](https://do-pun-images.s3.amazonaws.com/SRE-Challenge-High-Level-VPC.png)

* App VPC: for stateless application 
* DB VPC: for only database

There are two VPCs, which are connected through VPC peering in a region `eu-west-1`


#### App VPC 

![App VPC](https://do-pun-images.s3.amazonaws.com/SRE-Challenge-App-VPC.png)

App VPC has 4 major components:

* Amazon EKS
* ELB
* EFS
* EC2 Instances

As shown in the diagram above, all the external request are coming through ELB which is in public subnet and sends the request to the private subnet.

There are 3 worker nodes on all the 3 availability zones, which are protected by a security group.  

Wordpress is a simple blogging engine, it stores assets in a directory which should be shared among all the pods to maintain consistency, for which EFS is being used to create persistent volume.




#### Connectivity between VPC
![VPC Peering](https://do-pun-images.s3.amazonaws.com/SRE-Challenge-VPC-Peering.png)

Above diagram is showing the connectivity b/w the VPC, there is VPC peering connection but the flow is restricted through security groups.

* Db security group: Inbound traffic is allowed from app vpc 
* App security group: Inbound is restricted from other vpc 




### Setup Instructions



#### Setup local environment to build the infra

##### Prerequisites 
To complete this setup, you will need the following:

* awscli (1.16.266)
* Terraform (v0.12.12)
* Kubectl

Note: Please make sure at least given or higher version installed.

#### Install AWS CLI
Please make  sure the version of awscli should be `aws-cli/1.16.266` or greater.

[Installation Instructions](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)

Verify the version 

```
$ aws --version

aws-cli/1.16.266 Python/3.6.8 Linux/3.10.0-957.27.2.el7.x86_64 botocore/1.13.2
```


#### Configure AWS CLI

``` aws configure ```
Please provide the required credentials 


### Install aws-iam-authenticator 
[Installation Instructions](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)

Verify aws-iam-authenticator 

```
$ aws-iam-authenticator version

{"Version":"v0.4.0","Commit":"c141eda34ad1b6b4d71056810951801348f8c367"}
```


#### Install terraform 

[Installation Instructions](https://learn.hashicorp.com/terraform/getting-started/install.html)


Verify terraform installation 

```
$ terraform -version
Terraform v0.12.12
```

#### Install Kubectl  

Please make sure kubectl is installed 

[Installation Instructions](https://kubernetes.io/docs/tasks/tools/install-kubectl/)




## Steps to create infrastructure
If you were able to successfully setup the local environment, then we can proceed to create infra.

#### Step 1: Clone this repository 


You should be able to see this directory structure.

```
.
|-- artifacts
|   |-- db-config-map.yaml
|   |-- efs-provisioner.yaml
|   |-- kustomization.yaml
|   |-- phpmyadmin.yaml
|   |-- wordpress-cli.yaml
|   `-- wordpress.yaml
|-- docker-compose.yml
|-- README.md
`-- terraform
    |-- db.tf
    |-- efs.tf
    |-- eks.tf
    |-- local_file.tf
    |-- main.tf
    |-- output.tf
    |-- variables.tf
    |-- vpc_peering.tf
    `-- vpc.tf
```
Note: db-config-map.yaml and efs-provisioner.yaml will get updated with latest configuration when we run `terraform apply`

#### Step 2 : Initialize Terraform 

Please go inside terraform directory.

``` $ cd terraform ```

Use `terraform init`, a command to initialize download provider plugins to your local system.

``` $ terraform init ```

Expected output would be something like this

``` 
Downloading terraform-aws-modules/vpc/aws 2.17.0 for app_vpc...
- app_vpc in .terraform/modules/app_vpc/terraform-aws-modules-terraform-aws-vpc-5358041
Downloading terraform-aws-modules/rds/aws 2.5.0 for db...
- db in .terraform/modules/db/terraform-aws-modules-terraform-aws-rds-454dba6
- db.db_instance in .terraform/modules/db/terraform-aws-modules-terraform-aws-rds-454dba6/modules/db_instance
- db.db_option_group in .terraform/modules/db/terraform-aws-modules-terraform-aws-rds-454dba6/modules/db_option_group
- db.db_parameter_group in .terraform/modules/db/terraform-aws-modules-terraform-aws-rds-454dba6/modules/db_parameter_group
- db.db_subnet_group in .terraform/modules/db/terraform-aws-modules-terraform-aws-rds-454dba6/modules/db_subnet_group
Downloading terraform-aws-modules/vpc/aws 2.17.0 for db_vpc...
- db_vpc in .terraform/modules/db_vpc/terraform-aws-modules-terraform-aws-vpc-5358041
Downloading terraform-aws-modules/eks/aws 6.0.2 for sre-challenge-cluster...
- sre-challenge-cluster in .terraform/modules/sre-challenge-cluster/terraform-aws-modules-terraform-aws-eks-1be1a02

Initializing the backend...

Initializing provider plugins...
- Checking for available provider plugins...
- Downloading plugin for provider "random" (hashicorp/random) 2.2.1...
- Downloading plugin for provider "kubernetes" (hashicorp/kubernetes) 1.9.0...
- Downloading plugin for provider "aws" (hashicorp/aws) 2.33.0...
- Downloading plugin for provider "local" (hashicorp/local) 1.4.0...
- Downloading plugin for provider "null" (hashicorp/null) 2.1.2...
- Downloading plugin for provider "template" (hashicorp/template) 2.1.2...

The following providers do not have any version constraints in configuration,
so the latest version was installed.

To prevent automatic upgrades to new major versions that may contain breaking
changes, it is recommended to add version = "..." constraints to the
corresponding provider blocks in configuration, with the constraint strings
suggested below.

* provider.kubernetes: version = "~> 1.9"

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary. 
```

#### Step 3:  Verify Terraform module installation 

```
$ terraform -version 

Terraform v0.12.12
+ provider.aws v2.33.0
+ provider.kubernetes v1.9.0
+ provider.local v1.4.0
+ provider.null v2.1.2
+ provider.random v2.2.1
+ provider.template v2.1.2
```

#### Step 4: Terraform Plan 
Now that you have the modules downloaded, run the `terraform plan` command

```
$ terraform plan 

Refreshing Terraform state in-memory prior to plan...
The refreshed state will be used to calculate this plan, but will not be
persisted to local or remote state storage.

module.sre-challenge-cluster.data.aws_iam_policy_document.cluster_assume_role_policy: Refreshing state...
module.sre-challenge-cluster.data.aws_region.current: Refreshing state...
module.sre-challenge-cluster.data.aws_ami.eks_worker: Refreshing state...
module.db.module.db_instance.data.aws_iam_policy_document.enhanced_monitoring: Refreshing state...
module.sre-challenge-cluster.data.aws_iam_policy_document.workers_assume_role_policy: Refreshing state...
module.sre-challenge-cluster.data.aws_caller_identity.current: Refreshing state...

(...)



 # module.db.module.db_subnet_group.aws_db_subnet_group.this[0] will be created
  + resource "aws_db_subnet_group" "this" {
      + arn         = (known after apply)
      + description = "Database subnet group for srechallengedb"
      + id          = (known after apply)
      + name        = (known after apply)
      + name_prefix = "srechallengedb-"
      + subnet_ids  = (known after apply)
      + tags        = {
          + "Environment" = "prod"
          + "Name"        = "srechallengedb"
          + "Owner"       = "root"
        }
    }

Plan: 97 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

Note: You didn't specify an "-out" parameter to save this plan, so Terraform
can't guarantee that exactly these actions will be performed if
"terraform apply" is subsequently run.

```
This will give you and output for the list of resources.

Once everything is ok, we can proceed to apply. 

```
$ terraform apply 


# module.db.module.db_subnet_group.aws_db_subnet_group.this[0] will be created
  + resource "aws_db_subnet_group" "this" {
      + arn         = (known after apply)
      + description = "Database subnet group for srechallengedb"
      + id          = (known after apply)
      + name        = (known after apply)
      + name_prefix = "srechallengedb-"
      + subnet_ids  = (known after apply)
      + tags        = {
          + "Environment" = "prod"
          + "Name"        = "srechallengedb"
          + "Owner"       = "root"
        }
    }

Plan: 97 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value:
```
This will prompt you for `yes or no`, please provide the required input and wait for the completion.

On completion output would be something like this

```
null_resource.eks_init: Provisioning with 'local-exec'...
null_resource.eks_init (local-exec): Executing: ["/bin/sh" "-c" "echo arn:aws:eks:eu-west-1:666546636210:cluster/sre-challenge-cluster.srechallengedb.cjj5b6k4ttwb.eu-west-1.rds.amazonaws.com"]
null_resource.eks_init (local-exec): arn:aws:eks:eu-west-1:666546636210:cluster/sre-challenge-cluster.srechallengedb.cjj5b6k4ttwb.eu-west-1.rds.amazonaws.com
null_resource.eks_init: Provisioning with 'local-exec'...
null_resource.eks_init (local-exec): Executing: ["/bin/sh" "-c" "aws eks --region eu-west-1 update-kubeconfig --name sre-challenge-cluster"]
null_resource.eks_init (local-exec): Added new context arn:aws:eks:eu-west-1:666546636210:cluster/sre-challenge-cluster to /root/.kube/config
null_resource.eks_init: Creation complete after 2s [id=8690297503346187397]

Apply complete! Resources: 97 added, 0 changed, 0 destroyed.

Outputs:

database_endpoint = srechallengedb.cjj5b6k4ttwb.eu-west-1.rds.amazonaws.com
```


#### Step 5: Verify infrastructure setup


``` 
$ kubectl get nodes 

```
The exected output would be


```
NAME                                       STATUS   ROLES    AGE     VERSION
ip-10-0-1-243.eu-west-1.compute.internal   Ready    <none>   5m45s   v1.14.7-eks-1861c5
ip-10-0-1-31.eu-west-1.compute.internal    Ready    <none>   5h10m   v1.14.7-eks-1861c5
ip-10-0-2-25.eu-west-1.compute.internal    Ready    <none>   5h11m   v1.14.7-eks-1861c5
ip-10-0-3-130.eu-west-1.compute.internal   Ready    <none>   5h10m   v1.14.7-eks-1861c5
ip-10-0-3-177.eu-west-1.compute.internal   Ready    <none>   5m45s   v1.14.7-eks-1861c5
```

There might be a chance that some of the nodes are not in ready state, then just wait for some time.

There are 5 nodes because there was a resource crunch earlier to run 3 wordpress pods and phpmyadmin. 


### Application Setup
Now we have infrasture ready to deploy the application.

Go inside the artifacts directory `cd artifacts`

```
$ kubectl apply -k ./

```


Check pods 

```
$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE     IP           NODE                                       NOMINATED NODE   READINESS GATES
default       phpmyadmin-fc65dfb98-hvlr4        1/1     Running   0          51m     10.0.3.89    ip-10-0-3-130.eu-west-1.compute.internal   <none>           <none>
default       wordpress-7644c97df9-7wsl9        1/1     Running   0          51m     10.0.3.156   ip-10-0-3-130.eu-west-1.compute.internal   <none>           <none>
default       wordpress-7644c97df9-bjg5d        1/1     Running   0          3m2s    10.0.3.194   ip-10-0-3-177.eu-west-1.compute.internal   <none>           <none>
default       wordpress-7644c97df9-pb74m        1/1     Running   0          3m2s    10.0.1.249   ip-10-0-1-243.eu-west-1.compute.internal   <none>           <none>
kube-system   aws-node-45csr                    1/1     Running   0          4m20s   10.0.3.177   ip-10-0-3-177.eu-west-1.compute.internal   <none>           <none>
kube-system   aws-node-64bhw                    1/1     Running   0          5h8m    10.0.3.130   ip-10-0-3-130.eu-west-1.compute.internal   <none>           <none>
kube-system   aws-node-dsrht                    1/1     Running   0          5h9m    10.0.2.25    ip-10-0-2-25.eu-west-1.compute.internal    <none>           <none>
kube-system   aws-node-pjrl8                    1/1     Running   0          4m20s   10.0.1.243   ip-10-0-1-243.eu-west-1.compute.internal   <none>           <none>
kube-system   aws-node-scs7x                    1/1     Running   0          5h9m    10.0.1.31    ip-10-0-1-31.eu-west-1.compute.internal    <none>           <none>
kube-system   coredns-759d6fc95f-cw8bm          1/1     Running   0          5h12m   10.0.1.136   ip-10-0-1-31.eu-west-1.compute.internal    <none>           <none>
kube-system   coredns-759d6fc95f-j65ss          1/1     Running   0          5h12m   10.0.1.237   ip-10-0-1-31.eu-west-1.compute.internal    <none>           <none>
kube-system   efs-provisioner-84c44656c-rts8f   1/1     Running   0          51m     10.0.2.139   ip-10-0-2-25.eu-west-1.compute.internal    <none>           <none>
kube-system   kube-proxy-bpxsx                  1/1     Running   0          4m20s   10.0.1.243   ip-10-0-1-243.eu-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-gbxrj                  1/1     Running   0          5h9m    10.0.1.31    ip-10-0-1-31.eu-west-1.compute.internal    <none>           <none>
kube-system   kube-proxy-lgh5c                  1/1     Running   0          4m20s   10.0.3.177   ip-10-0-3-177.eu-west-1.compute.internal   <none>           <none>
kube-system   kube-proxy-pjd2q                  1/1     Running   0          5h9m    10.0.2.25    ip-10-0-2-25.eu-west-1.compute.internal    <none>           <none>
kube-system   kube-proxy-znrz6                  1/1     Running   0          5h8m    10.0.3.130   ip-10-0-3-130.eu-west-1.compute.internal   <none>           <none>

```
As it can be seen in 


Get Services url 

```
$ kubectl get svc 
NAME         TYPE           CLUSTER-IP       EXTERNAL-IP                                                               PORT(S)        AGE
kubernetes   ClusterIP      172.20.0.1       <none>                                                                    443/TCP        5h16m
phpmyadmin   LoadBalancer   172.20.234.229   ab1c95bddf85f11e98a9f0a9c5c921a3-1113710917.eu-west-1.elb.amazonaws.com   80:31132/TCP   55m
wordpress    LoadBalancer   172.20.191.232   ab1fd70adf85f11e98a9f0a9c5c921a3-228703617.eu-west-1.elb.amazonaws.com    80:31611/TCP   55m

```

Copy the load balancer url and try it in a browser.

Both wordpress and phpmyadmin url should be accessible in a browser.





