package institute.hopesoftware;

import java.util.Map;

import lombok.Data;
import software.amazon.awscdk.SecretValue;
import software.constructs.Node;

@Data
public class UserPoolConfiguration {
    public static final String Key = "userPoolConfiguration";
    public static final String KEY_ENABLED = "enabled";
    public static final String KEY_GOOGLE_LOGIN_CONFIGURATION = "googleLoginConfiguration";
    public static final String KEY_GOOGLE_LOGIN_CLIENT_SECRET = "google/login/clientSecret";
    public static final String KEY_GOOGLE_CLIENT_ID = "clientId";
    public static final String KEY_SELFSIGNIN_ENABLED = "selfSignUpEnabled";
    
    private boolean enabled;

    private boolean googleLoginEnabled;
    private SecretValue googleClientSecret;
    private String googleClientId;
    private boolean selfSignupEnabled;

    public static UserPoolConfiguration fromContextNode(Node node) throws Exception {
        @SuppressWarnings("unchecked")
        Map<String, Object> configuration = (Map<String, Object>) node.tryGetContext(Key);
        var enabled = (Boolean) configuration.get(KEY_ENABLED);

        UserPoolConfiguration userPoolConfiguration = new UserPoolConfiguration();
        userPoolConfiguration.setEnabled(enabled);

        @SuppressWarnings("unchecked")
        Map<String, Object> googleLoginConfiguration = (Map<String, Object>) configuration.get(KEY_GOOGLE_LOGIN_CONFIGURATION);
        userPoolConfiguration.setGoogleLoginEnabled((Boolean) googleLoginConfiguration.getOrDefault("enabled", false));

        userPoolConfiguration.setSelfSignupEnabled((Boolean) googleLoginConfiguration.getOrDefault(KEY_SELFSIGNIN_ENABLED, true));

        if (userPoolConfiguration.isGoogleLoginEnabled()) {
            String clientId = (String) googleLoginConfiguration.getOrDefault(KEY_GOOGLE_CLIENT_ID, "");
            Validations.requireNonEmpty(KEY_GOOGLE_CLIENT_ID, clientId);
            userPoolConfiguration.setGoogleClientId(clientId);
            
            SecretValue googleClientSecret = SecretValue.secretsManager(KEY_GOOGLE_LOGIN_CLIENT_SECRET);
            userPoolConfiguration.setGoogleClientSecret(googleClientSecret);           
        }

        return userPoolConfiguration;
    }

    
}
