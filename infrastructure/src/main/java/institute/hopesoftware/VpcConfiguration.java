package institute.hopesoftware;

import static institute.hopesoftware.ConfigurationUtilities.makeKey;
import static institute.hopesoftware.ConfigurationUtilities.readBooleanFromContext;

import lombok.Data;
import software.constructs.Node;

@Data
public class VpcConfiguration {
    public static final String Key = "vpcConfiguration";
    public static final String KEY_USE_DEFAULT = makeKey(Key, "useDefault");
    private boolean useDefault = true;

    public VpcConfiguration() {

    }

    public static VpcConfiguration fromContextNode(Node node) throws ConfigurationTypeException, ConfigurationValueMissingException {
        VpcConfiguration vpcConfiguration = new VpcConfiguration();

        boolean useDefaultVPC = readBooleanFromContext(node, KEY_USE_DEFAULT);

        vpcConfiguration.setUseDefault(useDefaultVPC);
        return vpcConfiguration;
    }
}
