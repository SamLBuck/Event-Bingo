package institute.hopesoftware;

import lombok.Getter;

public class ConfigurationTypeException extends Exception {

    @Getter     
    private String key;
    
    @Getter    
    private String expectedType;

    @Getter
    private Object valueProvided;

    public ConfigurationTypeException(String key, String expectedType, Object value) {
        this.key = key;
        this.expectedType = expectedType;
        this.valueProvided = value;
    }

    @Override
    public String toString() {
        return String.format("The value provided for the key %s in config.json was expected to be a %s\nThe value provided was %s which was parsed as a %s", key, expectedType, valueProvided, valueProvided.getClass().toString());
    }
}
