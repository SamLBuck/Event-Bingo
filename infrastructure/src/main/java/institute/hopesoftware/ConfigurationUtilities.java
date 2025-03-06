package institute.hopesoftware;

import java.util.List;

import software.constructs.Node;

public class ConfigurationUtilities {

    protected static String makeKey(String rootKey, String... components) {
        StringBuffer buffer = new StringBuffer();
        buffer.append(rootKey);
        for (String component : components) {
            buffer.append(".");
            buffer.append(component);
        }
        return buffer.toString();
    }

    public static boolean readBooleanFromContext(Node node, String key) throws ConfigurationTypeException, ConfigurationValueMissingException {
        var valueAsObject = (Object) node.tryGetContext(key);   
        if (valueAsObject == null) {
            throw new ConfigurationValueMissingException(key);
        }             
        if (valueAsObject instanceof Boolean) {
            return (Boolean) valueAsObject;            
        }
        else if (valueAsObject instanceof String) {
            String valueAsString = (String) valueAsObject;
            if (valueAsString.matches("[0-9]+")) {
                return Integer.parseInt(valueAsString) != 0;                
            }            
            else {
                return Boolean.valueOf((String) valueAsObject);
            }
        }
        else {
            throw new ConfigurationTypeException(key, "Boolean", valueAsObject);
        }
    }
    
    public static int readIntFromContext(Node node, String key) throws ConfigurationTypeException, ConfigurationValueMissingException {
        var valueAsObject = (Object) node.tryGetContext(key);  
        if (valueAsObject == null) {
            throw new ConfigurationValueMissingException(key);
        }              
        if (valueAsObject instanceof Integer) {
            return (Integer) valueAsObject;            
        }
        else if (valueAsObject instanceof String) {
            return Integer.valueOf((String) valueAsObject);
        }
        else {
            throw new ConfigurationTypeException(key, "Integer", valueAsObject);
        }
    }

    public static String readStringFromContext(Node node, String key) throws ConfigurationTypeException, ConfigurationValueMissingException {
        var valueAsObject = (Object) node.tryGetContext(key);      
        if (valueAsObject == null) {
            throw new ConfigurationValueMissingException(key);
        }          
        if (valueAsObject instanceof String) {
            return (String) valueAsObject;            
        }
        else {
            throw new ConfigurationTypeException(key, "String", valueAsObject);
        }
    }

    @SuppressWarnings("unchecked")
    public static List<String> readListStringsFromContext (Node node, String key) throws ConfigurationTypeException {
        var valueAsObject = (Object) node.tryGetContext(key);     
        System.err.println("Looking at " + valueAsObject + " for property " + key + " in readListStringsFromContext");           
        if (valueAsObject instanceof List) {
            
            return (List<String>) valueAsObject;            
        }
        else if (valueAsObject instanceof String) {
            String stringValue = (String) valueAsObject;            
            return List.<String>of(stringValue.split(","))
                .stream()
                .filter(s -> s.length() > 0).toList();
        }
        else {
            throw new ConfigurationTypeException(key, "List<String>", valueAsObject);
        }
    }
}
