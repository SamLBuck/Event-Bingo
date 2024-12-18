package institute.hopesoftware;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import dev.stratospheric.cdk.ApplicationEnvironment;
import dev.stratospheric.cdk.Network.NetworkInputParameters;
import software.amazon.awscdk.App;
import software.amazon.awscdk.Environment;
import software.amazon.jsii.JsiiError;

public class InfrastructureApp {
    public static void main(final String[] args) {
        App app = new App();

        String accountId = (String) app.getNode().tryGetContext("accountId");
        Validations.requireNonEmpty(accountId, "accountId");

        String region = (String) app.getNode().tryGetContext("region");
        Validations.requireNonEmpty(region, "region");

        String environmentName = (String) app.getNode().tryGetContext("environmentName");
        Validations.requireNonEmpty(environmentName, "environmentName");

        String applicationName = (String) app.getNode().tryGetContext("applicationName");
        Validations.requireNonEmpty(applicationName, "applicationName");

        String sslCertificateARN = (String) app.getNode().tryGetContext("sslCertificateARN");
        Validations.requireNonEmpty(sslCertificateARN, "context variable 'sslCertificateARN' must not be null");

        String dockerImageTag = (String) app.getNode().tryGetContext("dockerImageTag");

        Environment awsEnvironment = Environment
                .builder()
                .account(accountId)
                .region(region)
                .build();

        ApplicationEnvironment applicationEnvironment = new ApplicationEnvironment(applicationName, environmentName);
     
        FoundationStack foundationStack = new FoundationStack(app, "FoundationStack", awsEnvironment, applicationEnvironment, accountId);                

        Set<ApplicationComponent> applicationComponents = new HashSet<ApplicationComponent> ();

        @SuppressWarnings("unchecked")
        Map<String, Object> userPoolConfiguration = (Map<String, Object>) app.getNode().tryGetContext("userPoolConfiguration");

        boolean buildUserPool = (Boolean) userPoolConfiguration.getOrDefault("enabled", false);

        if (buildUserPool) {
            applicationComponents.add(ApplicationComponent.COGNITO_USER_POOL);
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> dbConfiguration = (Map<String, Object>) app.getNode().tryGetContext(DbConfiguration.Key);
        boolean buildDb = (Boolean) dbConfiguration.getOrDefault(DbConfiguration.KEY_ENABLED, false);
        if (buildDb) {
            applicationComponents.add(ApplicationComponent.POSTGRES_DATABASE);
        }
        
        try {
            NetworkInputParameters networkInputParameters = 
                new NetworkInputParameters().withSslCertificateArn(sslCertificateARN);

            ApplicationStack applicationStack = new ApplicationStack(app, String.format("%s-application-stack", applicationName), awsEnvironment, applicationEnvironment, applicationComponents, networkInputParameters);
            applicationStack.addDependency(foundationStack);

            app.synth();
        }
        catch (JsiiError badConfiguration) {
            String message = badConfiguration.getMessage();
            if (message.contains("clientSecret")) {
                String errorMessage = String.format("You must configure the Google Client Secret in the AWS Secrets Manager using the key %s", UserPoolConfiguration.KEY_GOOGLE_LOGIN_CLIENT_SECRET);
                System.err.println(errorMessage);
                System.exit(1);
            }
            else {
                System.err.println(badConfiguration);
            }
        }
        catch (Exception ex) {
                System.err.println(ex);
                System.exit(1);
        }
    }
}

