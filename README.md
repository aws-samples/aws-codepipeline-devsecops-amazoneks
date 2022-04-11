# Automatically build and deploy a Java application to Amazon EKS using a CI/CD pipeline

### Overview:
Create a continuous integration and continuous delivery (CI/CD) pipeline that automatically builds and deploys a Java application to an Amazon Elastic Kubernetes Service (Amazon EKS) cluster on the Amazon Web Services (AWS) Cloud. This pattern uses a greeting application developed with a Spring Boot Java framework and that uses Apache Maven.

This solution will be useful to build the code for a Java application, package the application artifacts as a Docker image, security scan the image, and upload the image as a workload container on Amazon EKS and can be also used as a reference to migrate from a tightly coupled monolithic architecture to a microservices architecture. 

It also emphasizes on how to monitor and manage the entire lifecycle of a Java application, which ensures a higher level of automation and helps avoid errors or bugs.

### High Level Architecture:

![Alt text](./architecture-diagram.png?raw=true "Architecture")

The diagram shows the following workflow:

1. Users raise a pull request (PR) with their Java application code changes to base branch of an AWS CodeCommit repository.

2. Amazon CodeGuru Reviewer automatically reviews the code as soon as a PR is raised and does a analysis of java code as per the best practices and gives recommendations to users,

3. Once PR is merged to base branch, a AWS CloudWatch event is created

4. This AWS CloudWatch event triggers the AWS CodePipeline

5. CodePipeline runs the build phase (continuous integration).

6. CodeBuild builds the artifact, packages the artifact to a Docker image, scans the image for security vulnerabilities by using Aqua Security Trivy, and stores the image in Amazon Elastic Container Registry (Amazon ECR).

7. The vulnerabilities detected from step6 are uploaded to AWS Security Hub for further analysis by users or developers, which provides overview, recommendations, remediation steps for the vulnerabilties.

8. Emails Notifications of various phases within the AWS CodePipeline are sent to the users via Amazon SNS.

9. After the continuous integration phases are complete, CodePipeline enters the deployment phase (continuous delivery).

10. The Docker image is deployed to Amazon EKS as a container workload (pod) using Helm charts. 

11. The application pod is configured with Amazon CodeGuru Profiler Agent which will send the profiling data of the application (CPU, Heap usage, Latency) to Amazon CodeGuru Profiler which is useful for developers to understand the behaviour of the application.

### Code Structure:

```bash
├── README
├── buildspec
│   ├── buildspec.yml
│   └── buildspec_deploy.yml
├── cf_templates
│   ├── build_deployment.yaml
│   ├── codecommit_ecr.yaml
│   └── kube_aws_auth_configmap_patch.sh
├── code
│   └── app
│       ├── Dockerfile
│       ├── pom.xml
│       └── src
│           └── main
│               ├── java
│               │   └── software
│               │       └── amazon
│               │           └── samples
│               │               └── greeting
│               │                   ├── Application.java
│               │                   └── GreetingController.java
│               └── resources
│                   └── Images
│                       └── aws_proserve.jpg
├── helm_charts
│   └── aws-proserve-java-greeting
│       ├── Chart.yaml
│       ├── templates
│       │   ├── NOTES.txt
│       │   ├── _helpers.tpl
│       │   ├── deployment.yaml
│       │   ├── hpa.yaml
│       │   ├── ingress.yaml
│       │   ├── service.yaml
│       │   ├── serviceaccount.yaml
│       │   └── tests
│       │       └── test-connection.yaml
│       └── values.dev.yaml
└── securityhub
    └── asff.tpl

```
### Code Overview:
1) **buildspec**: BuildSpec yaml files, buildspec.yml (For Build Phase), buildspec_deploy.yml (For Deploy Phase)
```bash
buildspec
│   ├── buildspec.yml (Build)
│   └── buildspec_deploy.yml (Deploy)
```

2) **cf_templates**: Cloudformation templates and EKS aws-auth configmap changes
```bash
cf_templates
├── build_deployment.yaml (Pipeline Stack Setup)
├── codecommit_ecr.yaml (Codecommit and ECR Setup)
└── kube_aws_auth_configmap_patch.sh (Providing access to Pipeline to deploy helm charts to EKS cluster)
```

3) **code**: Sample Spring Boot application source code (src folder), Dockerfile and pom.xml
```bash
code
└── app
    ├── Dockerfile
    ├── pom.xml
    └── src
        └── main
            ├── java
            │   └── software
            │       └── amazon
            │           └── samples
            │               └── greeting
            │                   ├── Application.java
            │                   └── GreetingController.java
            └── resources
                └── Images
                    └── aws_proserve.jpg
```

4) **helm_charts**: Helm charts to deploy application to EKS Cluster
```bash
helm_charts
└── aws-proserve-java-greeting
    ├── Chart.yaml
    ├── templates
    │   ├── NOTES.txt
    │   ├── _helpers.tpl
    │   ├── deployment.yaml
    │   ├── hpa.yaml
    │   ├── ingress.yaml
    │   ├── service.yaml
    │   ├── serviceaccount.yaml
    │   └── tests
    │       └── test-connection.yaml
    └── values.dev.yaml
```

5) **securityhub**: ASFF template (AWS Security Finding Format, part of AWS SeurityHub service). This format will be used for uploading docker image vulnerabilties details to AWS SecurityHub
```bash
securityhub
└── asff.tpl
```


**Setup Procedure:**

1) Upload code zip to S3 Bucket:<br/>
   (Ensure git and python 3.x are installed in your local workstation)
- Clone the repository to your local workstation<br/>

     `git clone <GitHub-Url>`

- Navigate to the repository and execute the commands in order as indicated below. This will create compressed version of the entire code with .zip extension(cicdstack.zip) and will validate the zip file too:<br/>
     ```bash
    cd <cloned-repository>
    python -m zipfile -c cicdstack.zip *
    python -m zipfile -t cicdstack.zip
   ```
   We have cicdstack.zip file ready and this will be used in next step.<br/>
      
- Sign in to the AWS Management Console, open the Amazon S3 console, and then create an S3 bucket.
   Create a folder in the S3 bucket. We recommend naming this folder “code.”
   Upload cicdstack.zip created in earlier step to the code folder in the S3 bucket.  


2) CodeCommitECR Creation:<br/>
   Ensure your AWS CodeCommit and Amazon ECR are in hand. If not, you can run the cloudformation template cf_templates/codecommit_ecr.yaml via AWS Console. Ensure the code in zip format is uploaded as per step 1.
   Give the parameter and their values:
```bash
   CodeCommitRepositoryBranchName  : Branch-name where the code resides. Put it as main for default
   CodeCommitRepositoryName        : Preferred Name of AWS CodeCommit repo to be created
   CodeCommitRepositoryS3Bucket    : S3 BucketName where the code zipfile resides
   CodeCommitRepositoryS3BucketObjKey : code/cicdstack.zip
   ECRRepositoryName               : Preferred Name of ECR repo to be created
```


3) Setup Java CICD Pipeline:<br/>
Run the cloudformation template cf_templates/build_deployment.yaml and give the parameter accordingly as mentioned below. Ensure you have the required parameter values ready with you.
```bash
   CodeBranchName   : Branch name of AWS CodeCommit repo, where your code resides
   EKSClusterName   : Name of your EKS Cluster (not EKSCluster ID)
   EKSCodeBuildAppName : in this case name of app helm chart (aws-proserve-java-greeting)
   EKSWorkerNodeRoleARN : ARN of EKS Worker nodes IAM role
   EKSWorkerNodeRoleName : Name of the IAM role assigned to EKS worker nodes
   EcrDockerRepository : Name of Amazon ECR repo where the docker images of your code will be stored
   EmailRecipient : Email Address where build notifications needs to be sent
   EnvType             : environment, e.g: dev (since we have values.dev.yaml in helm_charts folder)
   SourceRepoName     : Name of AWS CodeCommit repo, where your code resides
```
   
This will automatically trigger the CodePipeline too.
Once the cloudformation template cf_templates/build_deployment.yaml executes successfully, go to Outputs tab of Java CICD CF Stack in AWS console and get the value of EksCodeBuildkubeRoleARN (this ARN needs to be added to configmap aws_auth of EKS cluster)

4) Patching aws_auth confmap with EksCodeBuildkubeRoleARN received from step3:
  Launch a terminal/powershell/cmd in your local workstation with aws cli installed and configured with access to EKS cluster in the AWS account.<br/>
  Login to EKS cluster:
```bash
aws eks update-kubeconfig --name <EKSClusterName> --region <AWSRegion>
```
Next, run the script: cf_templates/kube_aws_auth_configmap_patch.sh in this way:
```bash
bash cf_templates/kube_aws_auth_configmap_patch.sh <EksCodeBuildkubeRoleARN>
```
This will add the IAM RoleArn in aws_auth configmap of the EKS cluster. Ensure that you are cluster creator of that EKS when running the above script.

5) Go to CodePipeline in AWS console, and there approve the Action 'ApprovaltoDeploy' and it will run the Deploy Phase. (Ensure step 4 is completed before you go to this step)
Once the Deploy phase is completed, go to logs of Deploy phase and get the URL of this app to access via browser.

