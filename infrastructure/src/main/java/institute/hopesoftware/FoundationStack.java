package institute.hopesoftware;

import dev.stratospheric.cdk.ApplicationEnvironment;
import dev.stratospheric.cdk.DockerRepository;
import dev.stratospheric.cdk.DockerRepository.DockerRepositoryInputParameters;
import software.amazon.awscdk.Environment;
import software.amazon.awscdk.Stack;
import software.amazon.awscdk.StackProps;
import software.constructs.Construct;

/**
 * This stack currently sets up a Docker repository to hold application 
 * images for the server side code.
 */
public class FoundationStack extends Stack {
    public FoundationStack(final Construct scope, final String id, final Environment awsEnvironment, final ApplicationEnvironment applicationEnvironment, final String accountId) {
        super(scope, id, StackProps.builder()
            .stackName(applicationEnvironment.prefix("Foundation"))
            .env(awsEnvironment).build()); 

        DockerRepositoryInputParameters repositoryInputParameters = new
            DockerRepositoryInputParameters(
                applicationEnvironment.getApplicationName(), accountId, 10, false
            );
            
        new DockerRepository(this, "DockerRepository", awsEnvironment, repositoryInputParameters);
    }


}
