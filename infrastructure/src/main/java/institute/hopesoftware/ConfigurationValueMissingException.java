package institute.hopesoftware;

import lombok.Getter;


public class ConfigurationValueMissingException extends Exception {
    @Getter
    private String key;

    public ConfigurationValueMissingException(String key) {
        this.key = key;
    }

    @Override
    public String toString () {
        return String.format("No value found for key %s", key);
    }

    @Override
    public String getMessage() {
       return toString();
    }
}
