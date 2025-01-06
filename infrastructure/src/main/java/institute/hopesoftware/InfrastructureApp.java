package institute.hopesoftware;

import dev.stratospheric.cdk.ApplicationEnvironment;
import dev.stratospheric.cdk.Network.NetworkInputParameters;
import software.amazon.awscdk.App;
import software.amazon.awscdk.Environment;
import software.amazon.jsii.JsiiError;

public class InfrastructureApp {
    public static void main(final String[] args) {    
        UserPoolConfiguration userPoolConfiguration = null;
        DbConfiguration dbConfiguration = null;
        ServiceConfiguration serviceConfiguration = null;
        VpcConfiguration vpcConfiguration = null;

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

        Environment awsEnvironment = Environment
                .builder()
                .account(accountId)
                .region(region)
                .build();

        ApplicationEnvironment applicationEnvironment = new ApplicationEnvironment(applicationName, environmentName);
     
        FoundationStack foundationStack = new FoundationStack(app, "FoundationStack", awsEnvironment, applicationEnvironment, accountId);                

        try {
            userPoolConfiguration = UserPoolConfiguration.fromContextNode(app.getNode());
            System.err.println(String.format("Enabled is %s from within InfrastructureApp user pool configuration", userPoolConfiguration.isEnabled()));
        }
        catch (Exception e) {
            System.err.println("Exception reading user pool configuration: " + e.getMessage());
            System.exit(1);
        }

        try {
            dbConfiguration = DbConfiguration.fromContextNode(app.getNode());
        }
        catch (Exception e) {
            System.err.println("Exception reading database configuration: " + e.getMessage());
            System.exit(1);
        }

        try {
            serviceConfiguration = ServiceConfiguration.fromContextNode(app.getNode());
        }
        catch (Exception e) {
            System.err.println("Exception reading service configuration: " + e.getMessage());
            System.exit(1);
        }
        
        try {
            vpcConfiguration = VpcConfiguration.fromContextNode(app.getNode());
        }
        catch (Exception e) {
            System.err.println("Exception reading VPC configuration: " + e.getMessage());
            System.exit(1);
        }

        try {
            NetworkInputParameters networkInputParameters = 
                new NetworkInputParameters().withSslCertificateArn(sslCertificateARN);

            String stackName = String.format("%s-application-stack", applicationName);
            ApplicationStack applicationStack = new ApplicationStack(
                app, stackName, awsEnvironment, applicationEnvironment, 
                dbConfiguration, 
                serviceConfiguration, 
                userPoolConfiguration,
                vpcConfiguration,
                networkInputParameters
            );

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

