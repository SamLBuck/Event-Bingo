package institute.hopesoftware;

import java.util.Arrays;
import java.util.List;
import java.util.Set;

import dev.stratospheric.cdk.ApplicationEnvironment;
import software.amazon.awscdk.Environment;
import software.amazon.awscdk.RemovalPolicy;
import software.amazon.awscdk.SecretValue;
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
import software.constructs.Construct;

public class ApplicationStack extends Stack {    
    private UserPool userPool;
    private UserPoolClient userPoolClient;
    private Environment awsEnvironment;
    private ApplicationEnvironment applicationEnvironment;

    public ApplicationStack(
        final Construct scope, final String id,
        final Environment awsEnvironment,
        final ApplicationEnvironment applicationEnvironment, 
        Set<ApplicationComponent> componentsToBuild)
    {
        super(scope, id, StackProps.builder()
            .stackName(applicationEnvironment.prefix("Application"))
            .env(awsEnvironment).build()
        );

        this.applicationEnvironment = applicationEnvironment;
        this.awsEnvironment = awsEnvironment;
        
        if (componentsToBuild.contains(ApplicationComponent.COGNITO_USER_POOL)) {
            setupCognito();
        }
    }

    private void setupCognito() {
        String applicationName = applicationEnvironment.getApplicationName();
        String userPoolName = String.format("%s-user-pool",applicationName);
        String userPoolClientName = String.format("%s-client", userPoolName);

        this.userPool = UserPool.Builder.create(this, "userPool")
                .userPoolName(userPoolName)
                .selfSignUpEnabled(false)
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

        AttributeMapping attributeMapping = AttributeMapping.builder()
                .email(ProviderAttribute.GOOGLE_EMAIL)
                .familyName(ProviderAttribute.GOOGLE_FAMILY_NAME)
                .givenName(ProviderAttribute.GOOGLE_GIVEN_NAME)
                .profilePicture(ProviderAttribute.GOOGLE_PICTURE)
                .build();

        UserPoolIdentityProviderGoogle provider = UserPoolIdentityProviderGoogle.Builder
                .create(this, "UserPoolIdentityProviderGoogle")
                .userPool(userPool)
                .clientId("427616320048-onrbei8rca7qb25re38bapn6lmo3e9jv.apps.googleusercontent.com")
                .clientSecretValue(SecretValue.secretsManager("google/login/clientSecret"))
                .attributeMapping(attributeMapping)
                .scopes(Arrays.asList("email", "profile", "phone", "openid"))
                .build();

        List<OAuthScope> oAuthScopes = Arrays.asList(
                OAuthScope.COGNITO_ADMIN, OAuthScope.EMAIL, OAuthScope.PROFILE);

        List<String> callbackUrls = Arrays.asList("http://localhost:3000/", "myapp://callback");
        List<String> logoutUrls = Arrays.asList("http://localhost:3000/", "myapp://logout");

        this.userPoolClient = UserPoolClient.Builder.create(this, "userPoolClient")
                .userPoolClientName(userPoolClientName)
                .generateSecret(false)
                .userPool(this.userPool)
                .oAuth(OAuthSettings.builder()
                        .flows(OAuthFlows.builder().authorizationCodeGrant(true).build())
                        .scopes(oAuthScopes)
                        .callbackUrls(callbackUrls)
                        .logoutUrls(logoutUrls)
                        .build())
                .supportedIdentityProviders(
                        Arrays.asList(UserPoolClientIdentityProvider.COGNITO,
                                UserPoolClientIdentityProvider.GOOGLE))
                .build();

        this.userPoolClient.getNode().addDependency(provider);
    }
}
