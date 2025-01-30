package institute.hopesoftware;

import static institute.hopesoftware.ConfigurationUtilities.makeKey;
import static institute.hopesoftware.ConfigurationUtilities.readListStringsFromContext;
import static institute.hopesoftware.ConfigurationUtilities.readStringFromContext;

import java.util.List;

import lombok.Data;
import software.amazon.awscdk.SecretValue;
import software.constructs.Node;
@Data
public class UserPoolConfiguration {
    public static final String Key = "cognito";
    public static final String KEY_ENABLED = makeKey(Key, "enabled");    
    public static final String KEY_SELFSIGNUP_ENABLED = makeKey(Key,"selfSignUpEnabled");

    public static final String KEY_GOOGLE_LOGIN_CONFIGURATION = makeKey(Key, "googleLogin");
    public static final String KEY_GOOGLE_LOGIN_ENABLED = makeKey(KEY_GOOGLE_LOGIN_CONFIGURATION, "enabled");

    public static final String KEY_GOOGLE_LOGIN_CLIENT_SECRET = "google/login/clientSecret";
    public static final String KEY_GOOGLE_CLIENT_ID = makeKey(KEY_GOOGLE_LOGIN_CONFIGURATION, "clientId");

    public static final String KEY_CALLBACK_URLS = makeKey(KEY_GOOGLE_LOGIN_CONFIGURATION, "callbackUrls");
    public static final String KEY_LOGOUT_URLS = makeKey(KEY_GOOGLE_LOGIN_CONFIGURATION, "logoutUrls");

    public static final String KEY_GROUP_NAMES = makeKey(Key, "groups");

    private boolean enabled;

    private boolean googleLoginEnabled;
    private SecretValue googleClientSecret;
    private String googleClientId;
    private boolean selfSignupEnabled;

    private List<String> callbackUrls;
    private List<String> logoutUrls;
    
    private List<String> groupNames;

    public static UserPoolConfiguration fromContextNode(Node node) throws Exception {
        UserPoolConfiguration userPoolConfiguration = new UserPoolConfiguration();
        
        var enabled = ConfigurationUtilities.readBooleanFromContext(node, KEY_ENABLED);
        userPoolConfiguration.setEnabled(enabled);
                        
        var selfSignUpEnabled = ConfigurationUtilities.readBooleanFromContext(node, KEY_SELFSIGNUP_ENABLED);
        userPoolConfiguration.setSelfSignupEnabled(selfSignUpEnabled);

        var groupNames = ConfigurationUtilities.readListStringsFromContext(node, KEY_GROUP_NAMES);
        userPoolConfiguration.setGroupNames(groupNames);

        var googleLoginEnabled = ConfigurationUtilities.readBooleanFromContext(node, KEY_GOOGLE_LOGIN_ENABLED);
        userPoolConfiguration.setGoogleLoginEnabled(googleLoginEnabled);

        if (userPoolConfiguration.isGoogleLoginEnabled()) {
            String clientId = readStringFromContext(node, KEY_GOOGLE_CLIENT_ID);
            try {
                Validations.requireNonEmpty(KEY_GOOGLE_CLIENT_ID, clientId);
            }
            catch (IllegalArgumentException badClientId) {
                throw new ConfigurationValueMissingException(KEY_GOOGLE_CLIENT_ID);
            }
            userPoolConfiguration.setGoogleClientId(clientId);
            
            SecretValue googleClientSecret = SecretValue.secretsManager(KEY_GOOGLE_LOGIN_CLIENT_SECRET);
            userPoolConfiguration.setGoogleClientSecret(googleClientSecret);           
        
            List<String> callbackUrls = readListStringsFromContext(node, KEY_CALLBACK_URLS);
            userPoolConfiguration.setCallbackUrls(callbackUrls);
            
            List<String> logoutUrls = readListStringsFromContext(node, KEY_LOGOUT_URLS);
            userPoolConfiguration.setLogoutUrls(logoutUrls);
        }
        return userPoolConfiguration;
    }
}
