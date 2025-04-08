package institute.hopesoftware;

import static institute.hopesoftware.ConfigurationUtilities.makeKey;
import static institute.hopesoftware.ConfigurationUtilities.readBooleanFromContext;
import static institute.hopesoftware.ConfigurationUtilities.readStringFromContext;

import lombok.Data;
import software.amazon.awscdk.services.ssm.StringParameter;
import software.constructs.Node;

@Data
public class PinpointConfiguration {
    public static final String Key = "notifications";
    public static final String KEY_ENABLED = makeKey(Key, "enabled");
    public static final String KEY_BUNDLE_ID = makeKey(Key, "bundleId");

    public static final String PARAMETER_STORE_TOKEN_KEY = "/pinpoint/apple/TokenKey";
    private static final String PARAMETER_STORE_TOKEN_KEY_ID = "/pinpoint/apple/TokenKeyId";
    private static final String PARAMETER_STORE_TEAM_ID = "/pinpoint/apple/TeamId";

    private boolean enabled;
    private String tokenKey;
    private String tokenKeyId;
    private String teamId;
    private String bundleId;

    public PinpointConfiguration () {
        enabled = false;
    }

    public static PinpointConfiguration fromContextNode(Node node) throws ConfigurationTypeException, ConfigurationValueMissingException {        
        PinpointConfiguration configuration = new PinpointConfiguration();
        configuration.setEnabled(readBooleanFromContext(node, KEY_ENABLED));
        configuration.setBundleId(readStringFromContext(node, KEY_BUNDLE_ID));
        return configuration;
    }

    public void readTokenInformationFromAWSParameterStore(ApplicationStack stack) {
        //  Unfortunately, there doesn't seem to be a way to test whether the parameter exists
        //  A placeholder is put in the CloudFormation template, and it's only when that template 
        //  is "executed" that CDK notices that the parameter doesn't exist
        //  The fact that the parameter is missing will be noticed by deploy.pl instead
        String parameterValue = StringParameter.fromStringParameterName(stack, "TokenKeyParameter", PARAMETER_STORE_TOKEN_KEY).getStringValue();
        setTokenKey(parameterValue);

        setTokenKeyId(StringParameter.fromStringParameterName(stack, "TokenKeyIdParameter", PARAMETER_STORE_TOKEN_KEY_ID).getStringValue());
        setTeamId(StringParameter.fromStringParameterName(stack, "TeamIdParameter", PARAMETER_STORE_TEAM_ID).getStringValue());
    }
}