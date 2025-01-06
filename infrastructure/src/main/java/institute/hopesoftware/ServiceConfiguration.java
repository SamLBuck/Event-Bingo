package institute.hopesoftware;

import static institute.hopesoftware.ConfigurationUtilities.makeKey;
import static institute.hopesoftware.ConfigurationUtilities.readBooleanFromContext;
import static institute.hopesoftware.ConfigurationUtilities.readIntFromContext;
import static institute.hopesoftware.ConfigurationUtilities.readStringFromContext;

import lombok.Data;
import software.constructs.Node;

@Data
public class ServiceConfiguration  {
    public final static String Key = "service";
    protected static final String KEY_ENABLED = makeKey(Key, "enabled");
    
    public final static String KEY_DOCKER_IMAGE_TAG = makeKey(Key, "dockerImageTag");
    public final static String KEY_DESIRED_INSTANCES = makeKey(Key, "desiredInstances");
    public final static String KEY_HEALTH_CHECK = makeKey(Key, "healthCheck");
    public final static String KEY_HEALTH_CHECK_PATH = makeKey (KEY_HEALTH_CHECK, "path");
    public final static String KEY_HEALTH_CHECK_PORT = makeKey (KEY_HEALTH_CHECK, "port");

    private boolean enabled;
    private String dockerImageTag;
    private String healthCheckPath;
    private Integer healthCheckPort;
    private Integer desiredInstances;

    public ServiceConfiguration () {

    }

    public static ServiceConfiguration fromContextNode(Node node) throws ConfigurationTypeException, ConfigurationValueMissingException {
        ServiceConfiguration configuration = new ServiceConfiguration();
        
        configuration.setEnabled(readBooleanFromContext(node, KEY_ENABLED));

        if (configuration.isEnabled()) {
            var dockerImageTag = readIntFromContext(node, KEY_DOCKER_IMAGE_TAG);
            System.err.println("Image tag: " + dockerImageTag);
            configuration.setDockerImageTag(String.valueOf(dockerImageTag));
            configuration.setDesiredInstances(readIntFromContext(node, KEY_DESIRED_INSTANCES));
            System.err.println("Desired instances: " + configuration.getDesiredInstances());

            System.err.println("Checking health check path: " + KEY_HEALTH_CHECK_PATH);
            configuration.setHealthCheckPath(readStringFromContext(node, KEY_HEALTH_CHECK_PATH));
            System.err.println("Health check path: " + configuration.getHealthCheckPath());

            configuration.setHealthCheckPort(readIntFromContext(node, KEY_HEALTH_CHECK_PORT));
        }
        return configuration;
    }
}
