package institute.hopesoftware;

import java.util.List;
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
    public static final String KEY_CALLBACK_URLS = "callbackUrls";
    public static final String KEY_LOGOUT_URLS = "logoutUrls";
    private boolean enabled;

    private boolean googleLoginEnabled;
    private SecretValue googleClientSecret;
    private String googleClientId;
    private boolean selfSignupEnabled;

    private List<String> callbackUrls;
    private List<String> logoutUrls;
    
    public static UserPoolConfiguration fromContextNode(Node node) throws Exception {
        UserPoolConfiguration userPoolConfiguration = new UserPoolConfiguration();

        @SuppressWarnings("unchecked")
        Map<String, Object> configuration = (Map<String, Object>) node.tryGetContext(Key);
        var enabled = (Boolean) configuration.get(KEY_ENABLED);
        userPoolConfiguration.setEnabled(enabled);

        userPoolConfiguration.setSelfSignupEnabled((Boolean) configuration.getOrDefault(KEY_SELFSIGNIN_ENABLED, true));

        @SuppressWarnings("unchecked")
        Map<String, Object> googleLoginConfiguration = (Map<String, Object>) configuration.get(KEY_GOOGLE_LOGIN_CONFIGURATION);
        userPoolConfiguration.setGoogleLoginEnabled((Boolean) googleLoginConfiguration.getOrDefault("enabled", false));

        if (userPoolConfiguration.isGoogleLoginEnabled()) {
            String clientId = (String) googleLoginConfiguration.getOrDefault(KEY_GOOGLE_CLIENT_ID, "");
            Validations.requireNonEmpty(KEY_GOOGLE_CLIENT_ID, clientId);
            userPoolConfiguration.setGoogleClientId(clientId);
            
            SecretValue googleClientSecret = SecretValue.secretsManager(KEY_GOOGLE_LOGIN_CLIENT_SECRET);
            userPoolConfiguration.setGoogleClientSecret(googleClientSecret);           
        }

        Object callbackUrls = configuration.get(KEY_CALLBACK_URLS);
        try {
            @SuppressWarnings("unchecked")
            List<String> callbackUrlsAsStrings = (List<String>) callbackUrls;
            userPoolConfiguration.setCallbackUrls(callbackUrlsAsStrings);
        }
        catch (ClassCastException invalidCallbackURLs) {
            throw new Exception(String.format("The value provided in cdk.json for the key %s is not a list of strings.", KEY_CALLBACK_URLS));
        }
        
        Object logoutUrls = configuration.get(KEY_LOGOUT_URLS);
        try {
            @SuppressWarnings("unchecked")
            List<String> logoutUrlsAsStrings = (List<String>) logoutUrls;
            userPoolConfiguration.setLogoutUrls(logoutUrlsAsStrings);
        }
        catch (ClassCastException invalidLogoutUrls) {
            throw new Exception(String.format("The value provided in cdk.json for the key %s is not a list of strings", KEY_LOGOUT_URLS));
        }

        return userPoolConfiguration;
    }

    
}
