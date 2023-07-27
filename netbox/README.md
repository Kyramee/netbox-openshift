# NetBox

Welcome to the documentation of the [NetBox] chart for OpenShift. This chart
support multiple installation options like standalone, with a bundle redis
instance, with bundle postgresql database instance or with both.

> **Note**  
> This chart was copied from the [bootc/netbox-chart] available on github. Some
> section of the documentation has been removed from the original since those
> sections do not apply in our environment.


## Prerequisite
Installing the Bitnami chart repo.

> **Important**  
> Make sure the Bitnami repo is not present under a different name before
> installing it. Having the same repo present multiple time with different names
> will cause issues.
> ```shell
> helm repo list
> ```

```shell
helm repo add bitnami https://charts.bitnami.com/bitnami
```

## TL;DR

This will install a NetBox instance with the default configuration.

```shell
git clone https://github.com/Kyramee/netbox-openshift.git
cd netbox-openshift/netbox
helm dependency build
helm install netbox -f values.yaml ./
  --set postgresql.auth.postgresPassword=[postgresPassword] \
  --set postgresql.auth.password=[netboxPassword] \
  --set redis.auth.password=[redisPassword]
```

The default configuration includes the required PostgreSQL and Redis database
services, but either or both may be managed externally if required.

## Production Usage

Always [use an existing Secret] and supply all passwords and secret keys
yourself to avoid Helm regenerating any of them for you.

> **Important**  
> You **MUST** minimally redefine **ALL** super user default parameters.  
> *"Admin is not a good username and an even more terrible password..."*  
> \- Me

It is strongly recommended to set both `postgresql.enabled` and `redis.enabled`
to `false` and use a separate external PostgreSQL and Redis instance. This
decouples those services from the chart's bundled versions which may have
complex upgrade requirements. It is also recommended to use a clustered
PostgreSQL server like the [Crunchy Postgres operator] for easy high
availability.

Run multiple replicas of the NetBox web front-end to avoid interruptions during
upgrades or at other times when the pods need to be restarted. There's no need
to have multiple workers (`worker.replicaCount`) for better availability. Set
up `affinity.podAntiAffinity` to avoid multiple NetBox pods being colocated on
the same node, for example:

```
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app.kubernetes.io/instance: netbox
            app.kubernetes.io/name: netbox
            app.kubernetes.io/component: netbox
        topologyKey: kubernetes.io/hostname
```

## Uninstalling the Chart

To delete the chart:

```shell
helm delete netbox
```

This will not delete the PersistenteVolumeClaims that NetBox, Redis and
postgresql generated with the installations. Those volumes can be used for data
migration or safe-keeping for later use.

If you do not need those PersistenteVolumeClaims you can delete them manually
with the web interface or the command line.

> **DANGER**  
> Deleting a PersistenteVolumeClaims will result in **permenent** data lost.
> Becareful when using a command like the one below.
> ```shell
> oc get pvc -o name | xargs  oc delete
> ```  
> This will result in the **permenent** removal of all PersistenteVolumeClaims
> and, most likely, all underlying persistent volumes of the current namespace.
> You are always better off using the selector flag of the oc delete command to
> specify exactly witch resources to delete.

## Upgrading

When upgrading or changing settings and using the bundled Bitnami PostgreSQL
sub-chart, you **must** provide the `postgresql.auth.password` at a minimum.
Ideally, you should also supply the `postgresql.auth.postgresPassword` and,
if using replication, the `postgresql.auth.replicationPassword`. Please see the
[upstream documentation] for further information.

### Upgrading the NetBox app

Here are the rules that one must respect in order to upgrade the NetBox default
version specified in the `appVersion` field of the [Chart.yaml].

#### The rules
- All configurable parameters available in NetBox must be present.
- Documentation **must** be updated.
- Deprecated fields must mark as such with the version cut off.
- Backward compatibility must be maintained to a reasonable limit.

You can consult the official NetBox documentation for any missing configurable
parameters to the [values.yaml]. Currently, the parameters appear in the same
order that they appear in the documentation and it would be nice if it's stayed
this way.

Do not forget to check the compatibility of new the new NetBox version with the 
bundle charts ([Bitnami Redis chart] and [Bitnami postgres chart]).

## Configuration

With more then 300 configurable parameters available on this chart

### Chart configuration

The following table lists the configurable parameters that control the chart
behaviour or affect all resources.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `nameOverride`                                  | Override the default value when defining netbox.name.               | `""`                                         |
| `fullnameOverride`                              | Override the default value when defining netbox.fullname            | `""`                                         |
| `useBundlePostgresql`                           | Set to true to use the bundled postgresql database                  | `true`                                       |
| `useBundleRedis`                                | Set to true to use the bundled Redis instance *                     | `true`                                       |
| `useExternalRedis`                              | Set to true to use a external Redis instance *                      | `false`                                      |
| `useSentinelRedis`                              | Set to true to use a Sentinel Redis instance *                      | `false`                                      |
| `useNetboxHousekeeping`                         | Enable NetBox housekeeping management dayly cronjob                 | `true`                                       |
| `useNetboxWorker`                               | Use a instance of NetBox worker along with NetBox main instance     | `true`                                       |
| `commonLabels`                                  | Labels that all resources will have                                 | `{}`                                         |
| `commonAnnotations`                             | Annotations that all resources will have                            | `{}`                                         |
| `existingSecret`                                | Name of the sercret that contain the necessary password             | `""`                                         |

> **Note**  
>\* Only one should be set to true

### NetBox image

The following table lists the configurable parameters that control where and
which version of NetBox the chart will pull and use.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `image.repository`                              | NetBox container image repository                                   | `netboxcommunity/netbox`                     |
| `image.pullPolicy`                              | NetBox container image pull policy                                  | `IfNotPresent`                               |
| `image.tag`                                     | NetBox container image tag (Valid Semver input only)                | `""`                                         |
| `image.imagePullSecrets`                        | Secrets needed for authentication for external repository           | `[]`                                         |

### NetBox super user

The following table lists the configurable parameters of the NetBox super user.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `superuser.name`                                | Super user name                                                     | `admin`                                      |
| `superuser.email`                               | Super user email                                                    | `admin@example.com`                          |
| `superuser.password`                            | Super user password                                                 | `admin`                                      |
| `superuser.apiToken`                            | Super user apiToken                                                 | `0123456789abcdef0123456789abcdef01234567`   |

### NetBox configuration (ConfigMap)

The following table lists the configurable parameters of NetBox.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `allowedHosts`                                  | List of valid FQDNs for this NetBox instance                        | `["*"]`                                      |
| `externalDatabase.host`                         | PostgreSQL host to use when `postgresql.enabled` is `false`         | `localhost`                                  |
| `externalDatabase.port`                         | Port number for external PostgreSQL                                 | `5432`                                       |
| `externalDatabase.database`                     | Database name for external PostgreSQL                               | `netbox`                                     |
| `externalDatabase.username`                     | Username for external PostgreSQL                                    | `netbox`                                     |
| `externalDatabase.password`                     | Password for external PostgreSQL                                    | `""`                                         |
| `externalDatabase.existingSecretName`           | Fetch password for external PostgreSQL from a different `Secret`    | `""`                                         |
| `externalDatabase.existingSecretKey`            | Key to fetch the password in the above `Secret`                     | `postgresql-password`                        |
| `externalDatabase.sslMode`                      | PostgreSQL client SSL Mode setting                                  | `prefer`                                     |
| `externalDatabase.connMaxAge`                   | The lifetime of a database connection, as an integer of seconds     | `300`                                        |
| `externalDatabase.disableServerSideCursors`     | Disable the use of server-side cursors transaction pooling          | `false`                                      |
| `externalDatabase.targetSessionAttrs`           | Determines whether the session must have certain properties         | `read-write`                                 |
| `tasksRedis.host`                               | Redis host to use when `redis.enabled` is `false`                   | `"netbox-redis"`                             |
| `tasksRedis.port`                               | Port number for external Redis                                      | `6379`                                       |
| `tasksRedis.username`                           | Username for external Redis                                         | `""`                                         |
| `tasksRedis.password`                           | Password for external Redis                                         | `""`                                         |
| `tasksRedis.database`                           | Redis database number used for NetBox task queue                    | `0`                                          |
| `tasksRedis.ssl`                                | Enable SSL when connecting to Redis                                 | `false`                                      |
| `tasksRedis.insecureSkipTlsVerify`              | Skip TLS certificate verification when connecting to Redis          | `false`                                      |
| `tasksRedis.caCertPath`                         | Path to CA certificates bundle for Redis (needs mounting manually)  | `""`                                         |
| `tasksRedis.existingSecretName`                 | Fetch password for external Redis from a different `Secret`         | `""`                                         |
| `tasksRedis.existingSecretKey`                  | Key to fetch the password in the above `Secret`                     | `redis-password`                             |
| `cachingRedis.host`                             | Redis host to use when `redis.enabled` is `false`                   | `"netbox-redis"`                             |
| `cachingRedis.port`                             | Port number for external Redis                                      | `6379`                                       |
| `cachingRedis.database`                         | Redis database number used for caching views                        | `1`                                          |
| `cachingRedis.username`                         | Username for external Redis                                         | `""`                                         |
| `cachingRedis.password`                         | Password for external Redis                                         | `""`                                         |
| `cachingRedis.ssl`                              | Enable SSL when connecting to Redis                                 | `false`                                      |
| `cachingRedis.insecureSkipTlsVerify`            | Skip TLS certificate verification when connecting to Redis          | `false`                                      |
| `cachingRedis.caCertPath`                       | Path to CA certificates bundle for Redis (needs mounting manually)  | `""`                                         |
| `cachingRedis.existingSecretName`               | Fetch password for external Redis from a different `Secret`         | `""`                                         |
| `cachingRedis.existingSecretKey`                | Key to fetch the password in the above `Secret`                     | `redis-password`                             |
| `externalTasksRedis.host`                       | Redis host to use when `redis.enabled` is `false`                   | `"netbox-redis"`                             |
| `externalTasksRedis.port`                       | Port number for external Redis                                      | `6379`                                       |
| `externalTasksRedis.username`                   | Username for external Redis                                         | `""`                                         |
| `externalTasksRedis.password`                   | Password for external Redis                                         | `""`                                         |
| `externalTasksRedis.database`                   | Redis database number used for NetBox task queue                    | `0`                                          |
| `externalTasksRedis.ssl`                        | Enable SSL when connecting to Redis                                 | `false`                                      |
| `externalTasksRedis.insecureSkipTlsVerify`      | Skip TLS certificate verification when connecting to Redis          | `false`                                      |
| `externalTasksRedis.caCertPath`                 | Path to CA certificates bundle for Redis (needs mounting manually)  | `""`                                         |
| `externalTasksRedis.existingSecretName`         | Fetch password for external Redis from a different `Secret`         | `""`                                         |
| `externalTasksRedis.existingSecretKey`          | Key to fetch the password in the above `Secret`                     | `redis-password`                             |
| `externalCachingRedis.host`                     | Redis host to use when `redis.enabled` is `false`                   | `"netbox-redis"`                             |
| `externalCachingRedis.port`                     | Port number for external Redis                                      | `6379`                                       |
| `externalCachingRedis.database`                 | Redis database number used for caching views                        | `1`                                          |
| `externalCachingRedis.username`                 | Username for external Redis                                         | `""`                                         |
| `externalCachingRedis.password`                 | Password for external Redis                                         | `""`                                         |
| `externalCachingRedis.ssl`                      | Enable SSL when connecting to Redis                                 | `false`                                      |
| `externalCachingRedis.insecureSkipTlsVerify`    | Skip TLS certificate verification when connecting to Redis          | `false`                                      |
| `externalCachingRedis.caCertPath`               | Path to CA certificates bundle for Redis (needs mounting manually)  | `""`                                         |
| `externalCachingRedis.existingSecretName`       | Fetch password for external Redis from a different `Secret`         | `""`                                         |
| `externalCachingRedis.existingSecretKey`        | Key to fetch the password in the above `Secret`                     | `redis-password`                             |
| `sentinelTasksRedis.sentinels`                  | List of sentinels in `host:port` format                             | `[]`                                         |
| `sentinelTasksRedis.sentinelService`            | Sentinel master service name                                        | `"netbox-redis"`                             |
| `sentinelTasksRedis.sentinelTimeout`            | Sentinel connection timeout, in seconds                             | `300`                                        |
| `sentinelTasksRedis.username`                   | Username for external Redis                                         | `""`                                         |
| `sentinelTasksRedis.password`                   | Password for external Redis                                         | `""`                                         |
| `sentinelTasksRedis.database`                   | Redis database number used for NetBox task queue                    | `0`                                          |
| `sentinelTasksRedis.ssl`                        | Enable SSL when connecting to Redis                                 | `false`                                      |
| `sentinelTasksRedis.insecureSkipTlsVerify`      | Skip TLS certificate verification when connecting to Redis          | `false`                                      |
| `sentinelTasksRedis.caCertPath`                 | Path to CA certificates bundle for Redis (needs mounting manually)  | `""`                                         |
| `sentinelTasksRedis.existingSecretName`         | Fetch password for external Redis from a different `Secret`         | `""`                                         |
| `sentinelTasksRedis.existingSecretKey`          | Key to fetch the password in the above `Secret`                     | `redis-password`                             |
| `sentinelCachingRedis.sentinels`                | List of sentinels in `host:port` format                             | `[]`                                         |
| `sentinelCachingRedis.sentinelService`          | Sentinel master service name                                        | `"netbox-redis"`                             |
| `sentinelCachingRedis.sentinelTimeout`          | Sentinel connection timeout, in seconds                             | `300`                                        |
| `sentinelCachingRedis.database`                 | Redis database number used for caching views                        | `1`                                          |
| `sentinelCachingRedis.username`                 | Username for external Redis                                         | `""`                                         |
| `sentinelCachingRedis.password`                 | Password for external Redis                                         | `""`                                         |
| `sentinelCachingRedis.ssl`                      | Enable SSL when connecting to Redis                                 | `false`                                      |
| `sentinelCachingRedis.insecureSkipTlsVerify`    | Skip TLS certificate verification when connecting to Redis          | `false`                                      |
| `sentinelCachingRedis.caCertPath`               | Path to CA certificates bundle for Redis (needs mounting manually)  | `""`                                         |
| `sentinelCachingRedis.existingSecretName`       | Fetch password for external Redis from a different `Secret`         | `""`                                         |
| `sentinelCachingRedis.existingSecretKey`        | Key to fetch the password in the above `Secret`                     | `redis-password`                             |
| `secretKey`                                     | Django secret key used for sessions and password reset tokens       | `""` (generated)                             |
| `basePath`                                      | Base URL path if accessing NetBox within a directory                | `""`                                         |
| `defaultLanguage`                               | Set the default preferred language/locale                           | `en-us`                                      |
| `email.server`                                  | SMTP server to use to send emails                                   | `localhost`                                  |
| `email.port`                                    | TCP port to connect to the SMTP server on                           | `25`                                         |
| `email.username`                                | Optional username for SMTP authentication                           | `""`                                         |
| `email.password`                                | Password for SMTP authentication (see also `existingSecret`)        | `""`                                         |
| `email.useSSL`                                  | Use SSL when connecting to the server                               | `false`                                      |
| `email.useTLS`                                  | Use TLS when connecting to the server                               | `false`                                      |
| `email.sslCertFile`                             | SMTP SSL certificate file path (e.g. in a mounted volume)           | `""`                                         |
| `email.sslKeyFile`                              | SMTP SSL key file path (e.g. in a mounted volume)                   | `""`                                         |
| `email.timeout`                                 | Timeout for SMTP connections, in seconds                            | `10`                                         |
| `email.from`                                    | Sender address for emails sent by NetBox                            | `""`                                         |
| `enableLocalization`                            | Localization                                                        | `false`                                      |
| `httpProxies`                                   | HTTP proxies NetBox should use when sending outbound HTTP requests  | `null`                                       |
| `internalIPs`                                   | IP addresses recognized as internal to the system                   | `['127.0.0.1', '::1']`                       |
| `logging`                                       | Custom Django logging configuration                                 | `{}`                                         |
| `mediaRoot`                                     | Media folder path                                                   | `"/opt/netbox/netbox/media"`                 |
| `reportsRoot`                                   | Custom reports folder path                                          | `"/opt/netbox/netbox/reports`                |
| `scriptsRoot`                                   | Scripts folder path                                                 | `"/opt/netbox/netbox/scripts`                |
| `storageBackend`                                | Django-storages backend class name                                  | `null`                                       |
| `storageConfig`                                 | Django-storages backend configuration                               | `{}`                                         |
| `allowTokenRetrieval`                           | Permit the retrieval of API tokens after their creation             | `false`                                      |
| `allowedUrlSchemes`                             | URL schemes that are allowed within links in NetBox                 | *See [values.yaml]*                          |
| `authPasswordValidators`                        | Configure validation of local user account passwords                | `[]`                                         |
| `corsOriginAllowAll`                            | [CORS]: allow all origins                                           | `false`                                      |
| `corsOriginWhitelist`                           | [CORS]: list of origins authorised to make cross-site HTTP requests | `[]`                                         |
| `corsOriginRegexWhitelist`                      | [CORS]: list of regex strings matching authorised origins           | `[]`                                         |
| `csrfCookieName`                                | Name of the CSRF authentication cookie                              | `csrftoken`                                  |
| `csrfTrustedOrigins`                            | A list of trusted origins for unsafe (e.g. POST) requests           | `[]`                                         |
| `exemptViewPermissions`                         | A list of models to exempt from the enforcement of view permissions | `[]`                                         |
| `loginPersistence`                              | Enables users to remain authenticated to NetBox indefinitely        | `false`                                      |
| `loginRequired`                                 | Permit only logged-in users to access NetBox                        | `false` (unauthenticated read-only access)   |
| `loginTimeout`                                  | How often to re-authenticate users                                  | `1209600` (14 days)                          |
| `logoutRedirectUrl`                             | View name or URL to which users are redirected after logging out    | `home`                                       |
| `sessionCookieName`                             | The name to use for the session cookie                              | `"sessionid"`                                |
| `remoteAuthAutoCreateUser`                      | Enables the automatic creation of new users                         | `true`                                       |
| `remoteAuthBackend`                             | Remote authentication backend class                                 | `netbox.authentication.RemoteUserBackend`    |
| `remoteAuthDefaultGroups`                       | A list of groups to assign to newly created users                   | `[]`                                         |
| `remoteAuthDefaultPermissions`                  | A list of permissions to assign newly created users                 | `{}`                                         |
| `remoteAuthEnabled`                             | Enable remote authentication support                                | `false`                                      |
| `remoteAuthGroupHeader`                         | The HTTP header which conveys the groups to which the user belongs  | `HTTP_REMOTE_USER_GROUP`                     |
| `remoteAuthGroupSeparator`                      | The Seperator upon which `remoteAuthGroupHeader` gets split into individual groups | `\|`                          |
| `remoteAuthGroupSyncEnabled`                    | Sync remote user groups from an HTTP header set by a reverse proxy  | `false`                                      |
| `remoteAuthHeader`                              | The name of the HTTP header which conveys the username              | `HTTP_REMOTE_USER`                           |
| `remoteAuthSuperuserGroups`                     | The list of groups that promote an remote User to Superuser on login| `[]`                                         |
| `remoteAuthSuperusers`                          | The list of users that get promoted to Superuser on login           | `[]`                                         |
| `remoteAuthStaffGroups`                         | The list of groups that promote an remote User to Staff on login    | `[]`                                         |
| `remoteAuthStaffUsers`                          | The list of users that get promoted to Staff on login               | `[]`                                         |
| `customValidators`                              | Custom validators for NetBox field values                           | `{}`                                         |
| `fieldChoices`                                  | Configure custom choices for certain built-in fields                | `{}`                                         |
| `defaultUserPreferences`                        | Default preferences for newly created user accounts                 | `{}`                                         |
| `paginateCount`                                 | The default number of objects to display per page in the web UI     | `50`                                         |
| `powerFeedDefaultAmperage`                      | Default amperage value for new power feeds                          | `15`                                         |
| `powerFeedMaxUtilisation`                       | Default maximum utilisation percentage for new power feeds          | `80`                                         |
| `powerFeedDefaultVoltage`                       | Default voltage value for new power feeds                           | `120`                                        |
| `rackElevationDefaultUnitHeight`                | Rack elevation default height in pixels                             | `22`                                         |
| `rackElevationDefaultUnitWidth`                 | Rack elevation default width in pixels                              | `220`                                        |
| `plugins`                                       | Additional plugins to load into NetBox                              | `[]`                                         |
| `pluginsConfig`                                 | Configuration for the additional plugins                            | `{}`                                         |
| `timeZone`                                      | The time zone NetBox will use when dealing with dates and times     | `UTC`                                        |
| `dateFormat`                                    | Django date format for long-form date strings                       | `"N j, Y"`                                   |
| `shortDateFormat`                               | Django date format for short-form date strings                      | `"Y-m-d"`                                    |
| `timeFormat`                                    | Django date format for long-form time strings                       | `"g:i a"`                                    |
| `shortTimeFormat`                               | Django date format for short-form time strings                      | `"H:i:s"`                                    |
| `dateTimeFormat`                                | Django date format for long-form date and time strings              | `"N j, Y g:i a"`                             |
| `shortDateTimeFormat`                           | Django date format for short-form date and time strongs             | `"Y-m-d H:i"`                                |
| `admins`                                        | List of admins to email about critical errors                       | `[]`                                         |
| `bannerBottom`                                  | Banner text to display at the bottom of every page                  | `""`                                         |
| `bannerLogin`                                   | Banner text to display on the login page                            | `""`                                         |
| `bannerTop`                                     | Banner text to display at the top of every page                     | `""`                                         |
| `changelogRetention`                            | Maximum number of days to retain logged changes (0 = forever)       | `90`                                         |
| `enforceGlobalUnique`                           | Enforce unique IP space in the global table (not in a VRF)          | `false`                                      |
| `fileUploadMaxMemorySize`                       | See [values.yaml] for full description                              | `2621440` (2.5MB)                            |
| `graphQlEnabled`                                | Enable the GraphQL API                                              | `true`                                       |
| `jobRetention`                                  | The number of days to retain job results (version >=3.5.x only)     | `90`                                         |
| `jobResultRetention`                            | **Deprecated**: Changed for `jobRetention` (version <=3.4.x only)   | `90`                                         |
| `maintenanceMode`                               | Display a "maintenance mode" banner on every page                   | `false`                                      |
| `mapsUrl`                                       | The URL to use when mapping physical addresses or GPS coordinates   | `https://maps.google.com/?q=`                |
| `maxPageSize`                                   | Maximum number of objects that can be returned by a single API call | `1000`                                       |
| `metricsEnabled`                                | Expose Prometheus metrics at the `/metrics` HTTP endpoint           | `false`                                      |
| `preferIPv4`                                    | Prefer devices' IPv4 address when determining their primary address | `false`                                      |
| `releaseCheckUrl`                               | Repository used to check if a new release of NetBox is available    | `null`                                       |
| `rqDefaultTimeout`                              | Maximum execution time for background tasks, in seconds             | `300` (5 minutes)                            |
| `debug`                                         | Enable NetBox debugging (NOT for production use)                    | `false`                                      |
| `ldapServerUri`                                 | See [django-auth-ldap]                                              | `""`                                         |
| `ldapStartTls`                                  | if StarTLS should be used                                           | *See [values.yaml]*                          |
| `ldapIgnoreCertErrors`                          | if Certificate errors should be ignored                             | *See [values.yaml]*                          |
| `ldapBindDn`                                    | Distinguished Name to bind with                                     | `""`                                         |
| `ldapBindPassword`                              | Password for bind DN                                                | `""`                                         |
| `ldapUserDnTemplate`                            | See [AUTH_LDAP_USER_DN_TEMPLATE]                                    | *See [values.yaml]*                          |
| `ldapUserSearchBaseDn`                          | See base_dn of [django_auth_ldap.config.LDAPSearch]                 | *See [values.yaml]*                          |
| `ldapUserSearchAttr`                            | User attribute name for user search                                 | `sAMAccountName`                             |
| `ldapGroupSearchBaseDn`                         | base DN for group search                                            | *See [values.yaml]*                          |
| `ldapGroupSearchClass`                          | [django-auth-ldap] for group search                                 | `group`                                      |
| `ldapGroupType`                                 | see [AUTH_LDAP_GROUP_TYPE]                                          | `GroupOfNamesType`                           |
| `ldapRequireGroupDn`                            | DN of a group that is required for login                            | `null`                                       |
| `ldapFindGroupPerms`                            | See [AUTH_LDAP_FIND_GROUP_PERMS]                                    | `true`                                       |
| `ldapMirrorGroups`                              | See [AUTH_LDAP_MIRROR_GROUPS]                                       | `null`                                       |
| `ldapCacheTimeout`                              | See [AUTH_LDAP_MIRROR_GROUPS_EXCEPT]                                | `null`                                       |
| `ldapIsAdminDn`                    | Required DN to be able to login in Admin-Backend, "is_staff"-Attribute of [AUTH_LDAP_USER_FLAGS_BY_GROUP] | *See [values.yaml]* |
| `ldapSsSuperUserDn`                | Required DN to receive SuperUser privileges, "is_superuser"-Attribute of [AUTH_LDAP_USER_FLAGS_BY_GROUP]  | *See [values.yaml]* |
| `ldapAttrFirstName`                | First name attribute of users, "first_name"-Attribute of [AUTH_LDAP_USER_ATTR_MAP]                        | `givenName`         |
| `ldapAttrLastName`                 | Last name attribute of users, "last_name"-Attribute of [AUTH_LDAP_USER_ATTR_MAP]                          | `sn`                |
| `ldapAttrMail`                     | Mail attribute of users, "email_name"-Attribute of [AUTH_LDAP_USER_ATTR_MAP]                              | `mail`              |
| `extraConfig`                                   | Additional NetBox configuration                                     | `[]`                                         |
| `napalm.username`                               | **Deprecated**: Username used by the NAPALM  (version <=3.4.x only) | `""`                                         |
| `napalm.password`                               | **Deprecated**: Password used by the NAPALM  (version <=3.4.x only) | `""`                                         |
| `napalm.timeout`                                | **Deprecated**: Timeout for NAPALM connection (version <=3.4.x only)| `30`                                         |
| `napalm.args`                                   | **Deprecated**: Dictionary of optional args (version <=3.4.x only)  | `{}`                                         |

### NetBox housekeeping (CronJob)

The following table lists the configurable parameters of NetBox housekeeping.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `housekeeping.concurrencyPolicy`                | ConcurrencyPolicy for the Housekeeping CronJob.                     | `Forbid`                                     |
| `housekeeping.failedJobsHistoryLimit`           | Number of failed jobs to keep in history                            | `5`                                          |
| `housekeeping.restartPolicy`                    | Restart Policy for the Housekeeping CronJob.                        | `OnFailure`                                  |
| `housekeeping.schedule`                         | Schedule for the CronJob in [Cron syntax].                          | `0 0 * * *` (Midnight daily)                 |
| `housekeeping.successfulJobsHistoryLimit`       | Number of successful jobs to keep in history                        | `5`                                          |
| `housekeeping.suspend`                          | Whether to suspend the CronJob                                      | `false`                                      |
| `housekeeping.podAnnotations`                   | Additional annotations for housekeeping CronJob pods                | `{}`                                         |
| `housekeeping.podLabels`                        | Additional labels for housekeeping CronJob pods                     | `{}`                                         |
| `housekeeping.podSecurityContext`               | Security context for housekeeping CronJob pods                      | *See [values.yaml]*                          |
| `housekeeping.extraInitContainers`              | Additional init containers for housekeeping CronJob pods            | `[]`                                         |
| `housekeeping.containers.securityContext`       | Security context for housekeeping CronJob containers                | *See [values.yaml]*                          |
| `housekeeping.containers.extraEnvs`             | Additional environment variables to set in housekeeping CronJob     | `[]`                                         |
| `housekeeping.containers.extraVolumeMounts`     | Additional volumes to mount in the housekeeping CronJob             | `[]`                                         |
| `housekeeping.containers.resources`             | Configure resource requests or limits for housekeeping CronJob      | `{}`                                         |
| `housekeeping.containers.extraContainers`       | Additional containers for housekeeping CronJob pods                 | `[]`                                         |
| `housekeeping.extraVolumes`                     | Additional volumes to reference in housekeeping CronJob pods        | `[]`                                         |
| `housekeeping.nodeSelector`                     | Node labels for housekeeping CronJob pod assignment                 | `{}`                                         |
| `housekeeping.affinity`                         | Affinity settings for housekeeping CronJob pod assignment           | `{}`                                         |
| `housekeeping.tolerations`                      | Toleration labels for housekeeping CronJob pod assignment           | `[]`                                         |

### NetBox Deployment

The following table lists the configurable parameters of NetBox Deployment.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `deployment.replicaCount`                       | The desired number of NetBox pods                                   | `1`                                          |
| `deployment.updateStrategy`                     | Configure deployment update strategy                                | `{}`                                         |
| `deployment.podAnnotations`                     | Additional annotations for NetBox pods                              | `{}`                                         |
| `deployment.podLabels`                          | Additional labels for NetBox pods                                   | `{}`                                         |
| `deployment.podSecurityContext`                 | Security context for NetBox pods                                    | *See [values.yaml]*                          |
| `deployment.initContainers.image.repository`    | Init container image repository                                     | `busybox`                                    |
| `deployment.initContainers.image.tag`           | Init container image tag                                            | `1.32.1`                                     |
| `deployment.initContainers.image.pullPolicy`    | Init container image pull policy                                    | `IfNotPresent`                               |
| `deployment.initContainers.resources`           | Configure resource requests or limits for init container            | `{}`                                         |
| `deployment.initContainers.securityContext`     | Security context for init container                                 | *See [values.yaml]*                          |
| `deployment.initContainers.extraInitContainers` | Additional init containers to run before starting main containers   | `[]`                                         |
| `deployment.containers.securityContext`         | Security context for NetBox containers                              | *See [values.yaml]*                          |
| `deployment.containers.skipStartupScripts`      | Skip [netbox-docker startup scripts]                                | `true`                                       |
| `deployment.containers.dbWaitDebug`             | Show details of errors that occur when applying migrations          | `false`                                      |
| `deployment.containers.extraEnvs`               | Additional environment variables to set in the NetBox container     | `[]`                                         |
| `deployment.containers.readinessProbe.enabled`  | Enable Kubernetes readinessProbe, see [readiness probes]            | `true`                                       |
| `deployment.containers.readinessProbe.initialDelaySeconds` | Number of seconds                                        | `0`                                          |
| `deployment.containers.readinessProbe.timeoutSeconds`      | Number of seconds                                        | `1`                                          |
| `deployment.containers.readinessProbe.periodSeconds`       | Number of seconds                                        | `10`                                         |
| `deployment.containers.readinessProbe.successThreshold`    | Number of seconds                                        | `1`                                          |
| `deployment.containers.extraVolumeMounts`       | Additional volumes to mount in the NetBox container                 | `[]`                                         |
| `deployment.containers.resources`               | Configure resource requests or limits for NetBox                    | `{}`                                         |
| `deployment.containers.extraContainers`         | Additional sidecar containers to be added to pods                   | `[]`                                         |
| `deployment.extraVolumes`                       | Additional volumes to reference in pods                             | `[]`                                         |
| `deployment.nodeSelector`                       | Node labels for pod assignment                                      | `{}`                                         |
| `deployment.affinity`                           | Affinity settings for pod assignment                                | `{}`                                         |
| `deployment.tolerations`                        | Toleration labels for pod assignment                                | `[]`                                         |
| `deployment.hostAliases`                        | List of hosts and IPs that will be added into the pod's hosts file  | `[]`                                         |
| `deployment.topologySpreadConstraints`          | Configure Pod Topology Spread Constraints for NetBox                | `[]`                                         |

### NetBox HorizontalPodAutoscaler

The following table lists the configurable parameters of NetBox HorizontalPodAutoscaler.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `autoscaling.enabled`                           | Whether to enable the HorizontalPodAutoscaler                       | `false`                                      |
| `autoscaling.minReplicas`                       | Minimum number of replicas when autoscaling is enabled              | `1`                                          |
| `autoscaling.maxReplicas`                       | Maximum number of replicas when autoscaling is enabled              | `100`                                        |
| `autoscaling.targetCPUUtilizationPercentage`    | Target CPU utilisation percentage for autoscaling                   | `80`                                         |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilisation percentage for autoscaling                | `80`                                         |

### NetBox Ingress

The following table lists the configurable parameters of NetBox Ingress.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `ingress.enabled`                               | Create an `Ingress` resource for accessing NetBox                   | `false`                                      |
| `ingress.className`                             | Use a named IngressClass                                            | `""`                                         |
| `ingress.annotations`                           | Extra annotations to apply to the `Ingress` resource                | `{}`                                         |
| `ingress.hosts`                                 | List of hosts and paths to map to the service                       | *See [values.yaml]*                          |
| `ingress.tls`                                   | TLS settings for the `Ingress` resource                             | `[]`                                         |

### NetBox PersistenteVolumeClaim

The following table lists the configurable parameters of both media and reports
NetBox PersistenteVolumeClaim.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `persistence.media.enabled`                     | Enable storage persistence for uploaded media (images)              | `true`                                       |
| `persistence.media.existingClaim`               | Use an existing `PersistentVolumeClaim` instead of creating one     | `""`                                         |
| `persistence.media.subPath`                     | Mount a sub-path of the volume into the container, not the root     | `""`                                         |
| `persistence.media.storageClass`                | Set the storage class of the PVC (use `-` to disable provisioning)  | `""`                                         |
| `persistence.media.selector`                    | Set the selector for PVs, if desired                                | `{}`                                         |
| `persistence.media.accessMode`                  | Access mode for the volume                                          | `ReadWriteOnce`                              |
| `persistence.media.size`                        | Size of persistent volume to request                                | `1Gi`                                        |
| `persistence.reports.enabled`                   | Enable storage persistence for NetBox reports                       | `false`                                      |
| `persistence.reports.existingClaim`             | Use an existing `PersistentVolumeClaim` instead of creating one     | `""`                                         |
| `persistence.reports.subPath`                   | Mount a sub-path of the volume into the container, not the root     | `""`                                         |
| `persistence.reports.storageClass`              | Set the storage class of the PVC (use `-` to disable provisioning)  | `""`                                         |
| `persistence.reports.selector`                  | Set the selector for PVs, if desired                                | `{}`                                         |
| `persistence.reports.accessMode`                | Access mode for the volume                                          | `ReadWriteOnce`                              |
| `persistence.reports.size`                      | Size of persistent volume to request                                | `1Gi`                                        |

### NetBox Service

The following table lists the configurable parameters of NetBox Service.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `service.annotations`                           | Annotations to add to the service account                           | `{}`                                         |
| `service.type`                                  | Type of `Service` resource to create                                | `ClusterIP`                                  |
| `service.port`                                  | Port number for the service                                         | `80`                                         |
| `service.nodePort`                              | The port used on the node when `service.type` is NodePort           | `""`                                         |
| `service.clusterIP`                             | The cluster IP address assigned to the service                      | `""`                                         |
| `service.clusterIPs`                            | A list of cluster IP addresses assigned to the service              | `[]`                                         |
| `service.externalIPs`                           | A list of external IP addresses aliased to this service             | `[]`                                         |
| `service.externalTrafficPolicy`                 | Policy for routing external traffic                                 | `""`                                         |
| `service.ipFamilyPolicy`                        | Represents the dual-stack-ness of the service                       | `""`                                         |
| `service.loadBalancerIP`                        | Request a specific IP address when `service.type` is LoadBalancer   | `""`                                         |
| `service.loadBalancerSourceRanges`              | A list of allowed IP ranges when `service.type` is LoadBalancer     | `[]`                                         |

### NetBox ServiceAccount

The following table lists the configurable parameters of NetBox ServiceAccount.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `serviceAccount.create`                         | Create a ServiceAccount for NetBox                                  | `true`                                       |
| `serviceAccount.annotations`                    | Annotations to add to the service account                           | `{}`                                         |
| `serviceAccount.name`                           | Name used instead of the `netbox.fullname` value when not empty     | `""`                                         |

### NetBox ServiceMonitor

The following table lists the configurable parameters of NetBox ServiceMonitor.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `serviceMonitor.enabled`                        | Whether to enable a [ServiceMonitor] for NetBox                     | `false`                                      |
| `serviceMonitor.additionalLabels`               | Additonal labels to apply to the ServiceMonitor                     | `{}`                                         |
| `serviceMonitor.interval`                       | Interval to scrape metrics.                                         | `1m`                                         |
| `serviceMonitor.scrapeTimeout`                  | Timeout duration for scraping metrics                               | `10s`                                        |

### NetBox Worker

The following table lists the configurable parameters of NetBox Worker.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `worker.replicaCount`                           | The desired number of NetBox Worker pods                            | `1`                                          |
| `worker.updateStrategy`                         | Configure deployment update strategy                                | `{}`                                         |
| `worker.podAnnotations`                         | Additional annotations for NetBox pods                              | `{}`                                         |
| `worker.podLabels`                              | Additional labels for NetBox pods                                   | `{}`                                         |
| `worker.podSecurityContext`                     | Security context for NetBox pods                                    | *See [values.yaml]*                          |
| `worker.extraInitContainers`                    | Additional init containers to run before starting main containers   | `[]`                                         |
| `worker.containers.securityContext`             | Security context for NetBox containers                              | *See [values.yaml]*                          |
| `worker.containers.extraEnvs`                   | Additional environment variables to set in the NetBox container     | `[]`                                         |
| `worker.containers.extraVolumeMounts`           | Additional volumes to mount in the NetBox container                 | `[]`                                         |
| `worker.containers.resources`                   | Configure resource requests or limits for NetBox                    | `{}`                                         |
| `worker.containers.extraContainers`             | Additional sidecar containers to be added to pods                   | `[]`                                         |
| `worker.extraVolumes`                           | Additional volumes to reference in pods                             | `[]`                                         |
| `worker.nodeSelector`                           | Node labels for pod assignment                                      | `{}`                                         |
| `worker.affinity`                               | Affinity settings for pod assignment                                | `{}`                                         |
| `worker.tolerations`                            | Toleration labels for pod assignment                                | `[]`                                         |
| `worker.hostAliases`                            | List of hosts and IPs that will be added into the pod's hosts file  | `[]`                                         |
| `worker.topologySpreadConstraints`              | Configure Pod Topology Spread Constraints for NetBox                | `[]`                                         |

### NetBox Worker HorizontalPodAutoscaler

The following table lists the configurable parameters of NetBox Worker HorizontalPodAutoscaler.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `workerAutoscaling.enabled`                     | Whether to enable the HorizontalPodAutoscaler                       | `false`                                      |
| `workerAutoscaling.minReplicas`                 | Minimum number of replicas when autoscaling is enabled              | `1`                                          |
| `workerAutoscaling.maxReplicas`                 | Maximum number of replicas when autoscaling is enabled              | `100`                                        |
| `workerAutoscaling.targetCPUUtilizationPercentage`    | Target CPU utilisation percentage for autoscaling             | `80`                                         |
| `workerAutoscaling.targetMemoryUtilizationPercentage` | Target memory utilisation percentage for autoscaling          | `80`                                         |

### NetBox connection test

The following table lists the configurable parameters of NetBox connection test.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `test.image.repository`                         | NetBox connection test container image repository                   | `busybox`                                    |
| `test.image.tag`                                | NetBox connection test container image tag                          | `1.32.1`                                     |
| `test.image.pullPolicy`                         | NetBox connection test container image pull policy                  | `IfNotPresent`                               |
| `test.resources`                                | Configure resource requests or limits for the container             | `{}`                                         |

### Bundle postgresql database override settings

The following table lists the configurable parameters of bundle postgresql
database override settingst.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `postgresql.auth.username`                      | Username to create for NetBox user in bundled PostgreSQL instance   | `netbox`                                     |
| `postgresql.auth.database`                      | Database to create for NetBox in bundled PostgreSQL instance        | `netbox`                                     |
| `postgresql.primary`                            | Override primary database values of the [Bitnami postgres chart]    | *See [values.yaml]*                          |
| `postgresql.readReplicas`                       | Override replicas database values the [Bitnami postgres chart]      | *See [values.yaml]*                          |

### Bundle Redis override settings

The following table lists the configurable parameters of bundle Redis override
settings.

| Parameter                                       | Description                                                         | Default                                      |
| ------------------------------------------------|---------------------------------------------------------------------|----------------------------------------------|
| `redis.master`                                  | Override Redis master values of the [Bitnami Redis chart]           | *See [values.yaml]*                          |
| `redis.replica`                                 | Override Redis replica values the [Bitnami Redis chart]             | *See [values.yaml]*                          |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install` or provide a YAML file containing the values for the above parameters:

```shell
$ helm install --name my-release bootc/netbox --values values.yaml
```

## Using an Existing Secret

Rather than specifying passwords and secrets as part of the Helm release values,
you may pass these to NetBox using a pre-existing `Secret` resource. When using
this, the `Secret` must contain the following keys:

| Key                    | Description                                                   | Required?                                                                             |
| -----------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `db_password`          | The password for the external PostgreSQL database             | If `postgresql.enabled` is `false` and `externalDatabase.existingSecretName` is unset |
| `email_password`       | SMTP user password                                            | Yes, but the value may be left blank if not required                                  |
| `ldap_bind_password`   | Password for LDAP bind DN                          | If `remoteAuth.enabled` is `true` and remoteAuthBackendnd` is `netbox.authentication.LDAPBackend`|
| `napalm_password`      | **Deprecated**: NAPALM user password (version <=3.4.x only)   | Yes, but the value may be left blank if not required                                  |
| `redis_tasks_password` | Password for the external Redis tasks database                | If `redis.enabled` is `false` and `tasksRedis.existingSecretName` is unset            |
| `redis_cache_password` | Password for the external Redis cache database                | If `redis.enabled` is `false` and `cachingRedis.existingSecretName` is unset          |
| `secret_key`           | Django secret key used for sessions and password reset tokens | Yes                                                                                   |
| `superuser_password`   | Password for the initial super-user account                   | Yes                                                                                   |
| `superuser_api_token`  | API token created for the initial super-user account          | Yes                                                                                   |

## Authentication
* [Single Sign On]
* [LDAP Authentication]

## License

> The following notice applies to all files contained within this Helm Chart and
> the Git repository which contains it:
>
> Copyright 2019-2020 Chris Boot
>
> Licensed under the Apache License, Version 2.0 (the "License");
> you may not use this file except in compliance with the License.
> You may obtain a copy of the License at
>
>     http://www.apache.org/licenses/LICENSE-2.0
>
> Unless required by applicable law or agreed to in writing, software
> distributed under the License is distributed on an "AS IS" BASIS,
> WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
> See the License for the specific language governing permissions and
> limitations under the License.


[//]: # "Link Section"

[NetBox]: https://netbox.readthedocs.io/
[bootc/netbox-chart]: https://github.com/bootc/netbox-chart
[use an existing Secret]: #using-an-existing-secret
[Crunchy Postgres operator]: https://access.crunchydata.com/documentation/postgres-operator/latest
[upstream documentation]: https://github.com/bitnami/charts/tree/master/bitnami/postgresql#upgrading
[Chart.yaml]: Chart.yaml
[values file]: values.yaml
[values.yaml]: values.yaml
[CORS]: https://github.com/ottoyiu/django-cors-headers
[django-auth-ldap]: https://django-auth-ldap.readthedocs.io
[AUTH_LDAP_USER_DN_TEMPLATE]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-user-dn-template
[django_auth_ldap.config.LDAPSearch]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#django_auth_ldap.config.LDAPSearch
[AUTH_LDAP_GROUP_TYPE]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-group-type
[AUTH_LDAP_FIND_GROUP_PERMS]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-find-group-perms
[AUTH_LDAP_MIRROR_GROUPS]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-mirror-groups
[AUTH_LDAP_MIRROR_GROUPS_EXCEPT]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-mirror-groups-except
[AUTH_LDAP_USER_FLAGS_BY_GROUP]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-user-flags-by-group
[AUTH_LDAP_USER_ATTR_MAP]: https://django-auth-ldap.readthedocs.io/en/latest/reference.html#auth-ldap-user-attr-map
[Cron syntax]: https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#cron-schedule-syntax
[netbox-docker startup scripts]: https://github.com/netbox-community/netbox-docker/tree/master/startup_scripts
[readiness probes]: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes
[ServiceMonitor]: https://prometheus-operator.dev/docs/operator/design/#servicemonitor
[Housekeeping]: https://demo.netbox.dev/static/docs/administration/housekeeping/
[Bitnami postgres chart]: https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml
[Bitnami Redis chart]: https://github.com/bitnami/charts/blob/main/bitnami/redis/values.yaml
[Single Sign On]: docs/auth.md#configuring-sso
[LDAP Authentication]: docs/auth.md#using-ldap-authentication
[here]: https://docs.netbox.dev/en/stable/