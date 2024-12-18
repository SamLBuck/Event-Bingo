package institute.hopesoftware;

import java.util.Map;

import lombok.Data;
import software.constructs.Node;

@Data
public class VpcConfiguration {
    public static final String Key = "vpcConfiguration";
    public static final String KEY_USE_DEFAULT = "useDefault";
    private boolean useDefault = true;

    public VpcConfiguration() {

    }

    public static VpcConfiguration fromContextNode(Node node) {
        VpcConfiguration vpcConfiguration = new VpcConfiguration();

        @SuppressWarnings("unchecked")
        Map<String, Object> configuration = (Map<String, Object>) node.tryGetContext(Key);

        vpcConfiguration.setUseDefault(
            (boolean) configuration.computeIfAbsent(KEY_USE_DEFAULT, (k) -> true)
        );
        return vpcConfiguration;
    }
}
