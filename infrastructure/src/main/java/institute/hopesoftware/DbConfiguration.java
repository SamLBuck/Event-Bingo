package institute.hopesoftware;

import static institute.hopesoftware.ConfigurationUtilities.makeKey;
import static institute.hopesoftware.ConfigurationUtilities.readBooleanFromContext;
import static institute.hopesoftware.ConfigurationUtilities.readIntFromContext;
import static institute.hopesoftware.ConfigurationUtilities.readStringFromContext;

import lombok.Data;
import software.constructs.Node;

@Data
public class DbConfiguration  {
    public static final String Key = "database";
    public static final String KEY_ENABLED = String.format("%s.enabled", Key);
    public static final String KEY_POSTGRES_VERSION = makeKey(Key, "postgresVersion");
    public static final String KEY_DB_INSTANCE_CLASS = makeKey(Key, "dbInstanceClass");
    public static final String KEY_ALLOCATED_STORAGE = makeKey(Key, "allocatedStorage");

    public boolean enabled;
    public String postgresVersion;
    public String dbInstanceClass;
    public Integer allocatedStorage;

    public DbConfiguration () {

    }

    public static DbConfiguration fromContextNode(Node node) throws ConfigurationTypeException, ConfigurationValueMissingException {
        DbConfiguration dbConfiguration = new DbConfiguration();

        boolean enabled = readBooleanFromContext(node, KEY_ENABLED);
        dbConfiguration.setEnabled(enabled);

        if (dbConfiguration.isEnabled()) {
            dbConfiguration.setPostgresVersion(readStringFromContext(node, KEY_POSTGRES_VERSION));
            dbConfiguration.setDbInstanceClass(readStringFromContext(node, KEY_DB_INSTANCE_CLASS));
            dbConfiguration.setAllocatedStorage(readIntFromContext(node, KEY_ALLOCATED_STORAGE));
        }
        return dbConfiguration;
    }
}
