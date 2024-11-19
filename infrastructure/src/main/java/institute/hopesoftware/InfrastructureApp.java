package institute.hopesoftware;

import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import dev.stratospheric.cdk.ApplicationEnvironment;
import software.amazon.awscdk.App;
import software.amazon.awscdk.Environment;

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

        try {
                ApplicationStack applicationStack = new ApplicationStack(app, String.format("%s-application-stack", applicationName), awsEnvironment, applicationEnvironment, applicationComponents);
                applicationStack.addDependency(foundationStack);

                app.synth();
        }
        catch (Exception ex) {
                System.err.println(ex);
                System.exit(1);
        }
    }
}

