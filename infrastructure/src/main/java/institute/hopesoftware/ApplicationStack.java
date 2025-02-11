package institute.hopesoftware;

import static java.util.Collections.singletonList;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

import dev.stratospheric.cdk.ApplicationEnvironment;
import dev.stratospheric.cdk.Network;
import dev.stratospheric.cdk.Network.NetworkInputParameters;
import dev.stratospheric.cdk.Service.DockerImageSource;
import software.amazon.awscdk.Environment;
import software.amazon.awscdk.RemovalPolicy;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.services.cognito.AccountRecovery;
import software.amazon.awscdk.services.cognito.AttributeMapping;
import software.amazon.awscdk.services.cognito.AutoVerifiedAttrs;
import software.amazon.awscdk.services.cognito.CfnUserPoolGroup;
import software.amazon.awscdk.services.cognito.CognitoDomainOptions;
import software.amazon.awscdk.services.cognito.Mfa;
import software.amazon.awscdk.services.cognito.OAuthFlows;
import software.amazon.awscdk.services.cognito.OAuthScope;
import software.amazon.awscdk.services.cognito.OAuthSettings;
import software.amazon.awscdk.services.cognito.ProviderAttribute;
import software.amazon.awscdk.services.cognito.SignInAliases;
import software.amazon.awscdk.services.cognito.UserPool;
import software.amazon.awscdk.services.cognito.UserPoolClient;
import software.amazon.awscdk.services.cognito.UserPoolClientIdentityProvider;
import software.amazon.awscdk.services.cognito.UserPoolDomainOptions;
import software.amazon.awscdk.services.cognito.UserPoolIdentityProviderGoogle;
import software.amazon.awscdk.services.ec2.CfnSecurityGroup;
import software.amazon.awscdk.services.ec2.CfnSecurityGroupIngress;
import software.amazon.awscdk.services.ec2.ISubnet;
import software.amazon.awscdk.services.ecr.IRepository;
import software.amazon.awscdk.services.ecr.Repository;
import software.amazon.awscdk.services.ecs.CfnService;
import software.amazon.awscdk.services.ecs.CfnTaskDefinition;
import software.amazon.awscdk.services.elasticloadbalancingv2.CfnListenerRule;
import software.amazon.awscdk.services.elasticloadbalancingv2.CfnTargetGroup;
import software.amazon.awscdk.services.iam.Effect;
import software.amazon.awscdk.services.iam.IManagedPolicy;
import software.amazon.awscdk.services.iam.ManagedPolicy;
import software.amazon.awscdk.services.iam.PolicyDocument;
import software.amazon.awscdk.services.iam.PolicyStatement;
import software.amazon.awscdk.services.iam.Role;
import software.amazon.awscdk.services.iam.ServicePrincipal;
import software.amazon.awscdk.services.logs.LogGroup;
import software.amazon.awscdk.services.logs.RetentionDays;
import software.amazon.awscdk.services.pinpoint.CfnApp;
import software.amazon.awscdk.services.rds.CfnDBInstance;
import software.amazon.awscdk.services.rds.CfnDBSubnetGroup;
import software.amazon.awscdk.services.secretsmanager.CfnSecretTargetAttachment;
import software.amazon.awscdk.services.secretsmanager.ISecret;
import software.amazon.awscdk.services.secretsmanager.Secret;
import software.amazon.awscdk.services.secretsmanager.SecretStringGenerator;
import software.constructs.Construct;

public class ApplicationStack extends Stack {
    private UserPool userPool;
    private UserPoolClient userPoolClient;
    private Environment awsEnvironment;
    private ApplicationEnvironment applicationEnvironment;    

    private Network network;
    private NetworkInputParameters networkInputParameters;

    private CfnDBInstance dbInstance;
    private ISecret databaseSecret;
    private CfnSecurityGroup databaseSecurityGroup;

    private UserPoolConfiguration userPoolConfiguration;
    private DbConfiguration dbConfiguration;
    private ServiceConfiguration serviceConfiguration;
    private VpcConfiguration vpcConfiguration;

    public ApplicationStack(
            final Construct scope, final String id,
            final Environment awsEnvironment,
            final ApplicationEnvironment applicationEnvironment,
            DbConfiguration dbConfiguration,
            ServiceConfiguration serviceConfiguration,
            UserPoolConfiguration userPoolConfiguration,
            VpcConfiguration vpcConfiguration,                        
            NetworkInputParameters networkInputParameters)
            throws Exception {
        super(scope, id, StackProps.builder()
                .stackName(applicationEnvironment.prefix("Application"))
                .env(awsEnvironment).build());

        this.applicationEnvironment = applicationEnvironment;
        this.awsEnvironment = awsEnvironment;
        this.networkInputParameters = networkInputParameters;
        this.userPoolConfiguration = userPoolConfiguration;
        this.vpcConfiguration = vpcConfiguration;
        this.dbConfiguration = dbConfiguration;
        this.serviceConfiguration = serviceConfiguration;

        if (userPoolConfiguration.isEnabled()) {
            setupCognito();
        }
        
        if (this.vpcConfiguration.isUseDefault()) {

        } else {
            network = createVpc();
        }

        if (dbConfiguration.enabled) {
            createPostgresDatabase();
        }

        CfnApp pinpointApp = CfnApp.Builder
            .create(this, "pinpoint-app")
            .name(applicationEnvironment.prefix("pinpoint-app"))
            .build();
            
        if (serviceConfiguration.isEnabled()) {
            createService();
        }
    }

    //  The following methods are taken from the Stratospheric Service.java construct
    //  https://github.com/stratospheric-dev/cdk-constructs/blob/main/src/main/java/dev/stratospheric/cdk/Service.java#L244
    private void allowIngressFromEcs(List<String> securityGroupIds, CfnSecurityGroup ecsSecurityGroup) {
        int i = 1;
        for (String securityGroupId : securityGroupIds) {
          CfnSecurityGroupIngress.Builder.create(this, "securityGroupIngress" + i)
            .sourceSecurityGroupId(ecsSecurityGroup.getAttrGroupId())
            .groupId(securityGroupId)
            .ipProtocol("-1")
            .build();
          i++;
        }
    }

    private String containerName(ApplicationEnvironment applicationEnvironment) {
        return applicationEnvironment.prefix("container");
    }

    private String sanitizeDbParameterName(String dbParameterName) {
        return dbParameterName
                // db name must have only alphanumerical characters
                .replaceAll("[^a-zA-Z0-9]", "")
                // db name must start with a letter
                .replaceAll("^[0-9]", "a");
    }

    private CfnTaskDefinition.KeyValuePairProperty keyValuePair(String key, String value) {
        return CfnTaskDefinition.KeyValuePairProperty.builder()
          .name(key)
          .value(value)
          .build();
    }

    public List<CfnTaskDefinition.KeyValuePairProperty> toKeyValuePairs(Map<String, String> map) {
        List<CfnTaskDefinition.KeyValuePairProperty> keyValuePairs = new ArrayList<>();
        for (Map.Entry<String, String> entry : map.entrySet()) {
          keyValuePairs.add(keyValuePair(entry.getKey(), entry.getValue()));
        }
        return keyValuePairs;
    }

    private void setupCognito() throws Exception {
        String applicationName = applicationEnvironment.getApplicationName();
        String userPoolName = String.format("%s-user-pool", applicationName);
        String userPoolClientName = String.format("%s-client", userPoolName);

        this.userPool = UserPool.Builder.create(this, "userPool")
                .userPoolName(userPoolName)
                .selfSignUpEnabled(userPoolConfiguration.isSelfSignupEnabled())
                .signInAliases(SignInAliases.builder().email(true).build())
                .autoVerify(AutoVerifiedAttrs.builder().email(true).build())
                .mfa(Mfa.OFF)
                .accountRecovery(AccountRecovery.EMAIL_ONLY)
                .removalPolicy(RemovalPolicy.DESTROY)
                .build();

        UserPoolDomainOptions options = UserPoolDomainOptions.builder()
                .cognitoDomain(CognitoDomainOptions.builder().domainPrefix(applicationName).build())
                .build();
        userPool.addDomain(applicationName, options);

        UserPoolClient.Builder userPoolClientBuilder = UserPoolClient.Builder.create(this, "userPoolClient")
                .userPoolClientName(userPoolClientName)
                .generateSecret(false)
                .userPool(this.userPool);

        List<UserPoolClientIdentityProvider> identityProviders = new ArrayList<UserPoolClientIdentityProvider>();
        identityProviders.add(UserPoolClientIdentityProvider.COGNITO);
        UserPoolIdentityProviderGoogle provider = null;

        if (userPoolConfiguration.isGoogleLoginEnabled()) {
            identityProviders.add(UserPoolClientIdentityProvider.GOOGLE);

            AttributeMapping attributeMapping = AttributeMapping.builder()
                    .email(ProviderAttribute.GOOGLE_EMAIL)
                    .familyName(ProviderAttribute.GOOGLE_FAMILY_NAME)
                    .givenName(ProviderAttribute.GOOGLE_GIVEN_NAME)
                    .profilePicture(ProviderAttribute.GOOGLE_PICTURE)
                    .build();

            provider = UserPoolIdentityProviderGoogle.Builder
                    .create(this, "UserPoolIdentityProviderGoogle")
                    .userPool(userPool)
                    .clientId(userPoolConfiguration.getGoogleClientId())
                    .clientSecretValue(userPoolConfiguration.getGoogleClientSecret())
                    .attributeMapping(attributeMapping)
                    .scopes(Arrays.asList("email", "profile", "phone", "openid"))
                    .build();

            List<OAuthScope> oAuthScopes = Arrays.asList(
                    OAuthScope.COGNITO_ADMIN, OAuthScope.EMAIL, OAuthScope.PROFILE);

            List<String> callbackUrls = userPoolConfiguration.getCallbackUrls();
            List<String> logoutUrls = userPoolConfiguration.getLogoutUrls();

            OAuthSettings oAuthSettings = OAuthSettings.builder()
                    .flows(OAuthFlows.builder().authorizationCodeGrant(true).build())
                    .scopes(oAuthScopes)
                    .callbackUrls(callbackUrls)
                    .logoutUrls(logoutUrls)
                    .build();

            userPoolClientBuilder = userPoolClientBuilder
                    .oAuth(oAuthSettings);
        }

        this.userPoolClient = userPoolClientBuilder
                .supportedIdentityProviders(identityProviders)
                .build();

        if (userPoolConfiguration.isGoogleLoginEnabled()) {
            this.userPoolClient.getNode().addDependency(provider);
        }

        for (String groupName: userPoolConfiguration.getGroupNames()) {
            CfnUserPoolGroup group = CfnUserPoolGroup.Builder.create(
                this, 
                String.format("%s-group-%s", applicationName, groupName)
            )
            .userPoolId(userPool.getUserPoolId())
            .groupName(groupName)
            .build();
            group.getNode().addDependency(userPool);
        }
    }

    private Network createVpc() {
        String id = String.format("%s-%s-VPC", applicationEnvironment.getApplicationName(),
                applicationEnvironment.getEnvironmentName());

        return new Network(this, id, awsEnvironment,
                applicationEnvironment.getEnvironmentName(), networkInputParameters);
    }

    private void createPostgresDatabase() {
        // This code is based on the Stratospheric PostgresDatabase construct
        // https://github.com/stratospheric-dev/cdk-constructs/blob/main/src/main/java/dev/stratospheric/cdk/PostgresDatabase.java
        String username = sanitizeDbParameterName(applicationEnvironment.prefix("dbUser"));

        databaseSecurityGroup = CfnSecurityGroup.Builder.create(this, "databaseSecurityGroup")
                .vpcId(network.getVpc().getVpcId())
                .groupDescription("Security Group for the database instance")
                .groupName(applicationEnvironment.prefix("dbSecurityGroup"))
                .build();

        // This will generate a JSON object with the keys "username" and "password".
        databaseSecret = Secret.Builder.create(this, "databaseSecret")
                .secretName(applicationEnvironment.prefix("DatabaseSecret"))
                .description("Credentials to the RDS instance")
                .generateSecretString(SecretStringGenerator.builder()
                        .secretStringTemplate(String.format("{\"username\": \"%s\"}", username))
                        .generateStringKey("password")
                        .passwordLength(32)
                        .excludeCharacters("@/\\\" ").build())
                .build();

        List<ISubnet> subnets = network.getVpc().getIsolatedSubnets();
        List<String> subnetIds = subnets.stream().map(addr -> addr.getSubnetId()).collect(Collectors.toList());
        CfnDBSubnetGroup subnetGroup = CfnDBSubnetGroup.Builder.create(this, "dbSubnetGroup")
                .dbSubnetGroupDescription("Subnet group for the RDS instance")
                .dbSubnetGroupName(applicationEnvironment.prefix("dbSubnetGroup"))
                .subnetIds(subnetIds)
                .build();

        String postgresVersion = dbConfiguration.getPostgresVersion();
        String dbInstanceClass = dbConfiguration.getDbInstanceClass();
        Integer allocatedStorage = dbConfiguration.getAllocatedStorage();

        dbInstance = CfnDBInstance.Builder.create(this, "postgresInstance")
                .dbInstanceIdentifier(applicationEnvironment.prefix("database"))
                .allocatedStorage(String.valueOf(allocatedStorage))
                .availabilityZone(network.getVpc().getAvailabilityZones().get(0))
                .dbInstanceClass(dbInstanceClass)
                .dbName(sanitizeDbParameterName(applicationEnvironment.prefix("database")))
                .dbSubnetGroupName(subnetGroup.getDbSubnetGroupName())
                .engine("postgres")
                .engineVersion(postgresVersion)
                .masterUsername(username)
                .masterUserPassword(databaseSecret.secretValueFromJson("password").unsafeUnwrap())
                .publiclyAccessible(false)
                .vpcSecurityGroups(Collections.singletonList(databaseSecurityGroup.getAttrGroupId()))
                .build();

        dbInstance.getNode().addDependency(subnetGroup);

        CfnSecretTargetAttachment.Builder.create(this, "secretTargetAttachment")
                .secretId(databaseSecret.getSecretArn())
                .targetId(dbInstance.getRef())
                .targetType("AWS::RDS::DBInstance")
                .build();

        dbInstance.getNode().addDependency(network);
    }

    private void createService() {
        Map<String, String> vars = new HashMap<String, String>();

        if (dbConfiguration.isEnabled()) {
            String jdbcUrl = String.format("jdbc:postgresql://%s:%s/%s",
                dbInstance.getAttrEndpointAddress(),
                dbInstance.getAttrEndpointPort(),
                sanitizeDbParameterName(applicationEnvironment.prefix("database"))
            );
            vars.put("SPRING_DATASOURCE_URL", jdbcUrl);

            String dbUserName = databaseSecret.secretValueFromJson("username").unsafeUnwrap();
            vars.put("SPRING_DATASOURCE_USERNAME", dbUserName);

            String dbPassword = databaseSecret.secretValueFromJson("password").unsafeUnwrap();
            vars.put("SPRING_DATASOURCE_PASSWORD", dbPassword);
        }

        DockerImageSource dockerImageSource = new DockerImageSource(applicationEnvironment.getApplicationName(), serviceConfiguration.getDockerImageTag());

        List<CfnTargetGroup.TargetGroupAttributeProperty> deregistrationDelayConfiguration = List.of(
            CfnTargetGroup.TargetGroupAttributeProperty.builder()
                .key("deregistration_delay.timeout_seconds")
                .value("5")
                .build()
        );

        List<CfnTargetGroup.TargetGroupAttributeProperty> targetGroupAttributes = new ArrayList<>(deregistrationDelayConfiguration);

        CfnTargetGroup targetGroup = CfnTargetGroup.Builder.create(this, "targetGroup")
            .healthCheckIntervalSeconds(30)
            .healthCheckPath(serviceConfiguration.getHealthCheckPath())
            .healthCheckPort(String.valueOf(serviceConfiguration.getHealthCheckPort()))
            .healthCheckProtocol("HTTP")
            .healthCheckTimeoutSeconds(5)
            .healthyThresholdCount(2)
            .unhealthyThresholdCount(8)
            .targetGroupAttributes(targetGroupAttributes)
            .targetType("ip")
            .port(8080)
            .protocol("HTTP")
            .vpcId(network.getVpc().getVpcId())
            .build();

        CfnListenerRule.ActionProperty actionProperty = CfnListenerRule.ActionProperty.builder()
            .targetGroupArn(targetGroup.getRef())
            .type("forward")
            .build();

        CfnListenerRule.RuleConditionProperty condition = CfnListenerRule.RuleConditionProperty.builder()
            .field("path-pattern")
            .values(singletonList("*"))
            .build();

        String httpsListenerArn = network.getHttpsListener().getListenerArn();
        Optional<String> optHttpsListenerArn = Optional.of(httpsListenerArn);

        // We only want the HTTPS listener to be deployed if the httpsListenerArn is
        // present.
        if (optHttpsListenerArn.isPresent()) {
            @SuppressWarnings("unused")
            CfnListenerRule httpsListenerRule = CfnListenerRule.Builder.create(this, "httpsListenerRule")
                .actions(singletonList(actionProperty))
                .conditions(singletonList(condition))
                .listenerArn(optHttpsListenerArn.get())
                .priority(1)
                .build();
        }

        CfnListenerRule httpListenerRule = CfnListenerRule.Builder.create(this, "httpListenerRule")
            .actions(singletonList(actionProperty))
            .conditions(singletonList(condition))
            .listenerArn(network.getHttpListener().getListenerArn())
            .priority(2)
            .build();

        LogGroup logGroup = LogGroup.Builder.create(this, "ecsLogGroup")
            .logGroupName(applicationEnvironment.prefix("logs"))
            .retention(RetentionDays.ONE_WEEK)
            .removalPolicy(RemovalPolicy.DESTROY)
            .build();

        Role ecsTaskExecutionRole = Role.Builder.create(this, "ecsTaskExecutionRole")
            .assumedBy(ServicePrincipal.Builder.create("ecs-tasks.amazonaws.com").build())
            .path("/")
            .inlinePolicies(Map.of(
                applicationEnvironment.prefix("ecsTaskExecutionRolePolicy"),
                PolicyDocument.Builder.create()
                    .statements(singletonList(
                        PolicyStatement.Builder.create()
                            .effect(Effect.ALLOW)
                            .resources(singletonList("*"))
                            .actions(Arrays.asList(
                            "ecr:GetAuthorizationToken",
                                "ecr:BatchCheckLayerAvailability",
                                "ecr:GetDownloadUrlForLayer",
                                "ecr:BatchGetImage",
                                "logs:CreateLogStream",
                                "logs:PutLogEvents")
                            )
                            .build()
                    )
                )
                .build()
                )
            )
        .build();

        //  Allow the task to access Cognition so Spring components can manage information within 
        //  the user pool
        IManagedPolicy cognitoPowerUser = ManagedPolicy.fromAwsManagedPolicyName("AmazonCognitoPowerUser");
        Role.Builder roleBuilder = Role.Builder.create(this, "ecsTaskRole")
            .assumedBy(
                ServicePrincipal.Builder.create("ecs-tasks.amazonaws.com").build()
            )
            .managedPolicies(Arrays.asList(cognitoPowerUser))
            .path("/");

        Role ecsTaskRole = roleBuilder.build();

        String dockerRepositoryUrl = null;
        if (dockerImageSource.isEcrSource()) {
            IRepository dockerRepository = Repository.fromRepositoryName(
                this, "ecrRepository",
                dockerImageSource.getDockerRepositoryName()
            );
            dockerRepository.grantPull(ecsTaskExecutionRole);
            dockerRepositoryUrl = dockerRepository
                    .repositoryUriForTag(dockerImageSource.getDockerImageTag());
        } else {
            dockerRepositoryUrl = dockerImageSource.getDockerImageUrl();
        }

        CfnTaskDefinition.ContainerDefinitionProperty container = CfnTaskDefinition.ContainerDefinitionProperty
            .builder()
            .name(containerName(applicationEnvironment))
            .cpu(256)
            .memory(512)
            .image(dockerRepositoryUrl)
            .logConfiguration(CfnTaskDefinition.LogConfigurationProperty.builder()
                .logDriver("awslogs")
                .options(Map.of(
                        "awslogs-group", logGroup.getLogGroupName(),
                        "awslogs-region", awsEnvironment.getRegion(),
                        "awslogs-stream-prefix", applicationEnvironment.prefix("stream"),
                        "awslogs-datetime-format", "%Y-%m-%dT%H:%M:%S.%f%z"))
                .build()
            )
            .portMappings(singletonList(CfnTaskDefinition.PortMappingProperty.builder()
                .containerPort(8080)
                .build())
            )
            .environment(toKeyValuePairs(vars))
            .stopTimeout(2)
            .build();

        CfnTaskDefinition taskDefinition = CfnTaskDefinition.Builder.create(this, "taskDefinition")
            // skipped family
            .cpu("256")
            .memory("512")
            .networkMode("awsvpc")
            .requiresCompatibilities(singletonList("FARGATE"))
            .executionRoleArn(ecsTaskExecutionRole.getRoleArn())
            .taskRoleArn(ecsTaskRole.getRoleArn())
            .containerDefinitions(singletonList(container))
            .build();

        CfnSecurityGroup ecsSecurityGroup = CfnSecurityGroup.Builder.create(this, "ecsSecurityGroup")
            .vpcId(network.getVpc().getVpcId())
            .groupDescription("SecurityGroup for the ECS containers")
            .build();

        // allow ECS containers to access each other
        @SuppressWarnings("unused")
        CfnSecurityGroupIngress ecsIngressFromSelf = CfnSecurityGroupIngress.Builder.create(this, "ecsIngressFromSelf")
            .ipProtocol("-1")
            .sourceSecurityGroupId(ecsSecurityGroup.getAttrGroupId())
            .groupId(ecsSecurityGroup.getAttrGroupId())
            .build();

        // allow the load balancer to access the containers
        @SuppressWarnings("unused")
        CfnSecurityGroupIngress ecsIngressFromLoadbalancer = CfnSecurityGroupIngress.Builder
            .create(this, "ecsIngressFromLoadbalancer")
            .ipProtocol("-1")
            .sourceSecurityGroupId(network.getLoadbalancerSecurityGroup().getSecurityGroupId())
            .groupId(ecsSecurityGroup.getAttrGroupId())
            .build();

        if (dbConfiguration.isEnabled()) {
            List<String> securityGroupIdsToGrantIngressFromEcs = Arrays.asList(
                databaseSecurityGroup.getAttrGroupId()
            );

            allowIngressFromEcs(securityGroupIdsToGrantIngressFromEcs, ecsSecurityGroup);
        }
        
        CfnService service = CfnService.Builder.create(this, "ecsService")
            .cluster(network.getEcsCluster().getClusterName())
            .launchType("FARGATE")
            .deploymentConfiguration(CfnService.DeploymentConfigurationProperty.builder()
                    .maximumPercent(200)
                    .minimumHealthyPercent(50)
                    .build())
            .desiredCount(serviceConfiguration.getDesiredInstances())
            .taskDefinition(taskDefinition.getRef())
            .loadBalancers(singletonList(CfnService.LoadBalancerProperty.builder()
                    .containerName(containerName(applicationEnvironment))
                    .containerPort(8080)
                    .targetGroupArn(targetGroup.getRef())
                    .build()))
            .networkConfiguration(CfnService.NetworkConfigurationProperty.builder()
                    .awsvpcConfiguration(CfnService.AwsVpcConfigurationProperty.builder()
                            .assignPublicIp("ENABLED")
                            .securityGroups(singletonList(ecsSecurityGroup.getAttrGroupId()))
                            .subnets(network.getOutputParameters().getPublicSubnets())
                            .build())
                    .build())
            .build();

        // Adding an explicit dependency from the service to the listeners to avoid "has
        // no load balancer associated" error
        // (see
        // https://stackoverflow.com/questions/61250772/how-can-i-create-a-dependson-relation-between-ec2-and-rds-using-aws-cdk).
        service.addDependsOn(httpListenerRule);

        applicationEnvironment.tag(this);

        service.getNode().addDependency(network);

        if (dbConfiguration.isEnabled()) {
            service.getNode().addDependency(dbInstance);
        }
    }

}
