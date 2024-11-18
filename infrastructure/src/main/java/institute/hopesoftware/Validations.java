package institute.hopesoftware;

/**
 * This class provides a static method to esnure that a particular 
 * variable has a value
 */
public class Validations {
    private Validations() {
    }

    public static void requireNonEmpty(String variableValue, String variableName) {
        String errorMessage;

        if (variableValue == null || variableValue.isBlank()) {
            errorMessage = String.format("%s must not be null or blank - %s", variableName, "set in cdk.json or specify on the command line using -c");
            throw new IllegalArgumentException(errorMessage);
        }

        if (variableValue.equals("default")) {
            errorMessage = String.format("Value of %s is set to 'default'; please replace with application-specific value in cdk.json or specify on the command line using -c");
            throw new IllegalArgumentException(errorMessage);
        }
    }
}
