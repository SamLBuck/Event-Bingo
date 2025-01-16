Make sure there are instructions on creating an AWS profile before doing anything else

Add the account ID for AWS into the Google Docs docments with the client ID and other AWS information

Add a note to make sure that they update aws-cli and amplify before getting started

#  Overview

Infrastructure for Hope Software Institute projects is hosted on AWS.  Projects specify the AWS services they required using the Java version of the Cloud Development Kit (CDK).  Most projects use the infrastructure from the HSI project template.

##  Specifying project-specific information associated with deployment
The file `infrastructure/cdk.json` contains several properties that must be edited before attempting to deploy the project's infrastructure to AWS.

### Properties needed for all projects

* **applicationName**:  the value for this property should be a descriptive name for the project, with no spaces or special characters.  It will be used to build names for the various AWS artifacts.
* **awsProfile**:  the name of an AWS profile containing an AWS *access key* and *secret access key*.  Information about creating an AWS profile with the required information can be found in the [HSI Project Docmentation](https://faculty.hope.edu/mcfall/courses/481/documentation/index.html).  
The credentials can be found a Google Drive Folder for the project that should be shared with the project team members.
* **accountId**:  the account ID for the AWS account associated with the account.  This information can also be found in Google Drive folder for the project.
* **sslCertificateARN**:  the unique AWS identifier for the SSL certificate associated with the project.  The value should be available in the Google Drive folder for the project.

### Specifying which AWS resources to deploy
Currently the project template supports the AWS resource types described below.

#### Cognito User Pools  
A User Pool is a resource dedicated to managing users and groups for an application.  It handles almost all operations associated with user management, including creating accounts, resetting passwords, two-factor authentication, and federated login using social providers.  **Google** is the only social login mechanism supported by the infrastructure template at this time.

To specify that a Cognito User Pool should be included when deploying a project,  the property `cognito.enabled` should be given a value of **true**.  The `cognito.selfSignUpEnabled` property controls whether users have the ability to sign up for an account on their own.  

Properties starting with `cognito.googleLogin` are used if the application should allow sign-in using Google authentication.  Several subproperties must then be configured:

* **cognito.googleLogin.clientId**:  Specifies the Client ID associated with a Google Cloud Platform project.  This project must be created separately using [the documentation provided here]((https://faculty.hope.edu/mcfall/courses/481/documentation/index.html)); a faculty or staff member will generally create this project and provide the client ID in the Google Drive folder for the project.
* **cognito.googleLogin.callbackUrls**:  This is an array of strings specifying allowable callback URLs.
  * **Flutter app**:  Include a URL like `"scheme://callback"` in the list of values for this property.  The value of *scheme* should be something that uniquely identifies the app.
  * **Web app**:  To be completed
* **cognito.googleLogin.logoutUrls**:  This is an array of strings specifying allowable logout URLs.
  * **Flutter app**: Include a URL like `"scheme://logout"` in the list of values for this property.  The value of *scheme* should be the same as the value used in the `cognito.googleLogin.callbackUrls` property.
  * **Web app**:  To be completed

#### Virtual Private Cloud (VPC)
A VPC allows servers you deploy as part of your infrastructure to communicate with each other. This would include your database server and the server hosting your backend / web application, for example.

The only property currently specified in `cdk.json` associated with the deployed VPC is `vpcConfiguration.useDefault`.  However, this property is currently ignored, and every project will create its own VPC.  This costs more, and it's hoped that eventually a VPC will not be created.

#### Postgres Database
Most applications will want to deploy an SQL database to store their data persistently.  The default value of **true** for the property `database.enabled` causes a server to be created.  

It's up to the project infrastructure to create schemas, tables, and other database resources; the infrastructure code simply creates an isolated instance of the PostgreSql server.

The following properties can be specified to customize the PostgreSql instance.  However, the default values that are provided are most likely appropriate.

* **database.postgresVersion**:  specifies the version of the Postgres software to run.
* **database.dbInstanceClass**:  the value of this property controls the processing power of the system running the Postgres server
* **database.allocatedStorage**:  how much storage, in GB, that can be used by the database.

####  Cluster / Service
This resource is the Spring Boot server serving the project's API / website.  You will almost always want to this resource built, which is why the default value of the `service.enabled` property is **true**.

The `service.dockerImageTag` property specifies which version of a Docker image to deploy as the software running on the cluster.  You generally shouldn't specify this value in `cdk.json` directly; it will be computed by the `deploy.pl` deployment script based on the tags associated with the project on your local machine.  

This does mean its best for a single project member to be responsible for deploying the project infrastructure; otherwise some coordination around Docker image tags will be required.

The other properties associated with the ECS service can likely be left at their defaults.

* **service.desiredInstances**:  the number of virtual machines running the server; a *load balancer* will automatically distributed the load between the VMs if there is more than 1.  
Most projects won't have a significant enough workload to justify the cost of setting this value to more than 1.
* **service.healthCheck.path**:  a URL which is accessed periodically by the AWS infrastructure to test whether it is up and working correctly.  
You **must** include the dependency shown below in your server's `pom.xml` to ensure the default value for this property is mapped to a Spring Boot provided endpoint.
    ````
    <dependency>
        <groupId>
            org.springframework.boot
        </groupId>
        <artifactId>
            spring-boot-starter-actuator
        </artifactId>
    </dependency>
    ````
*  **service.healthCheck.port**:  this is the port the Spring Server is running on internally to the cluster.

##  Deploying the system
After ensuring an AWS profile is configured on your system and modifying the values in `cdk.json` as necessary, you can execute the Perl script `deploy.pl` from the root of your project.

You can control which system components are built using the following command line arguments to `deploy.pl`:

*  **--webapp**:  This will compile the Flutter web application in the `web` folder and store the compiled resources in `src/main/resources/static/app`.  This file will be acessible from the project's domain using a URL like **https://domain.hopesoftware.institute/app/index.html**.
* **--server**:  This will compile the Spring Boot project in the `server` folder, storing the compiled resources in `server\target`.  This folder is referenced by the `Dockerfile` which is used to create the Docker image which is deployed to AWS.

The default values for both of these properties is set to 1, meaning they will be built unless you specify otherwise by passing the arguments `--no-webapp` / `--no-server`, respectively.