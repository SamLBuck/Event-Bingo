package institute.hopesoftware;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import dev.stratospheric.cdk.ApplicationEnvironment;
import dev.stratospheric.cdk.Network;
import dev.stratospheric.cdk.Network.NetworkInputParameters;
import software.amazon.awscdk.Environment;
import software.amazon.awscdk.RemovalPolicy;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.amazon.awscdk.services.cognito.AccountRecovery;
import software.amazon.awscdk.services.cognito.AttributeMapping;
import software.amazon.awscdk.services.cognito.AutoVerifiedAttrs;
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
import software.amazon.awscdk.services.ec2.ISubnet;
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
    private Construct scope;

    private Network network;
    private NetworkInputParameters networkInputParameters;

    private CfnDBInstance dbInstance;
    private ISecret databaseSecret;
    private CfnSecurityGroup databaseSecurityGroup;

    public ApplicationStack(
        final Construct scope, final String id,
        final Environment awsEnvironment,
        final ApplicationEnvironment applicationEnvironment, 
        Set<ApplicationComponent> componentsToBuild, NetworkInputParameters networkInputParameters) throws Exception
    {
        super(scope, id, StackProps.builder()
            .stackName(applicationEnvironment.prefix("Application"))
            .env(awsEnvironment).build()
        );

        this.scope = scope;
        this.applicationEnvironment = applicationEnvironment;
        this.awsEnvironment = awsEnvironment;
        this.networkInputParameters = networkInputParameters;
        
        if (componentsToBuild.contains(ApplicationComponent.COGNITO_USER_POOL)) {
            setupCognito();
        }

        VpcConfiguration vpcConfiguration = VpcConfiguration.fromContextNode(scope.getNode());
        if (vpcConfiguration.isUseDefault()) {
            
        }
        else {
            network = createVpc();
        }

        if (componentsToBuild.contains(ApplicationComponent.POSTGRES_DATABASE)) {
            DbConfiguration dbConfiguration = DbConfiguration.fromContextNode(scope.getNode());
            createPostgresDatabase(dbConfiguration);
        }
    }

    private void setupCognito() throws Exception {
        UserPoolConfiguration userPoolConfiguration = UserPoolConfiguration.fromContextNode(scope.getNode());

        String applicationName = applicationEnvironment.getApplicationName();
        String userPoolName = String.format("%s-user-pool",applicationName);
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

        UserPoolClient.Builder userPoolClientBuilder = 
            UserPoolClient.Builder.create(this, "userPoolClient")
                .userPoolClientName(userPoolClientName)
                .generateSecret(false)
                .userPool(this.userPool);

        List<UserPoolClientIdentityProvider> identityProviders = new ArrayList<UserPoolClientIdentityProvider> ();
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
    }

    private Network createVpc() {
        String id = String.format("%s-%s-VPC", applicationEnvironment.getApplicationName(), applicationEnvironment.getEnvironmentName());

        return new Network(this, id, awsEnvironment,
                applicationEnvironment.getEnvironmentName(), networkInputParameters);
    }

    private String sanitizeDbParameterName(String dbParameterName) {
        return dbParameterName
            // db name must have only alphanumerical characters
            .replaceAll("[^a-zA-Z0-9]", "")
            // db name must start with a letter
            .replaceAll("^[0-9]", "a");
    }

    private void createPostgresDatabase(DbConfiguration dbConfiguration) {
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
        double allocatedStorage = dbConfiguration.getAllocatedStorage();

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
}
