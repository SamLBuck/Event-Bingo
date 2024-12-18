package institute.hopesoftware;

import java.util.Map;

import lombok.Data;
import software.constructs.Node;

@Data
public class DbConfiguration {
    public static final String Key = "dbConfiguration";
    public static final String KEY_ENABLED = "enabled";
    public static final String KEY_POSTGRES_VERSION = "postgresVersion";
    public static final String KEY_DB_INSTANCE_CLASS = "dbInstanceClass";
    public static final String KEY_ALLOCATED_STORAGE = "allocatedStorage";

    public boolean enabled;
    public String postgresVersion;
    public String dbInstanceClass;
    public Integer allocatedStorage;

    public DbConfiguration () {

    }

    public static DbConfiguration fromContextNode(Node node) throws ConfigurationTypeException {
        DbConfiguration dbConfiguration = new DbConfiguration();

         @SuppressWarnings("unchecked")
        Map<String, Object> configuration = (Map<String, Object>) node.tryGetContext(Key);
        var enabled = (Boolean) configuration.get(KEY_ENABLED);

        dbConfiguration.setEnabled(enabled);

        if (dbConfiguration.isEnabled()) {
            Object objPostgresVersion = configuration.get(KEY_POSTGRES_VERSION);
            try {
                dbConfiguration.setPostgresVersion((String) objPostgresVersion);
            }
            catch (ClassCastException badPostgresVersion) {
                throw new ConfigurationTypeException(KEY_POSTGRES_VERSION, "String", objPostgresVersion);                
            }
            
            Object objDbInstanceClass = configuration.get(KEY_DB_INSTANCE_CLASS);

            try {
                dbConfiguration.setDbInstanceClass((String) objDbInstanceClass);
            }
            catch (ClassCastException badDbInstanceClass) {
                throw new ConfigurationTypeException(KEY_DB_INSTANCE_CLASS, "String", objDbInstanceClass);
            }

            Object objAllocatedStorage = configuration.get(KEY_ALLOCATED_STORAGE);
            try {
                dbConfiguration.setAllocatedStorage((Integer) objAllocatedStorage);
            }
            catch (ClassCastException badAllocatedStorage) {
                throw new ConfigurationTypeException(KEY_ALLOCATED_STORAGE, "Integer", objAllocatedStorage);
            }
        }
        return dbConfiguration;
    }
}
