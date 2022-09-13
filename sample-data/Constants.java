package com.partior.accessmanager.constants;

/**
 * Constants class contains constant related to private key,public key, algorithm, client related information,
 * cluster information
 */
public class Constants {
    public static final String BEARER_TOKEN_HEADER = "authorization";
    public static final String BEARER_INDICATOR = "Bearer ";
    public static final String CLIENT_IP_HEADER = "X-Real-IP";
    public static final String MESSAGE_ID_HEADER = "X-Msg-Id";
    public static final String MESSAGE_TYPE_HEADER = "X-Msg-Type";
    public static final String SYSTEM_ID_HEADER = "X-System-Id";

    public static final String SENDER_SYSTEM_ID_HEADER = "Sender-System-Id";
    public static final String RECEIVER_SYSTEM_ID_HEADER = "Receiver-System-Id";

    public static final String KEY_ALGO_RSA = "RSA";
    public static final String ENCRYPT_ALGO_RSA_INSTANCE = "RSA/ECB/OAEPWithSHA-256AndMGF1Padding";
    public static final String ENCRYPT_ALGO_RSA_DIGEST = "SHA-256";
    public static final String ENCRYPT_ALGO_RSA_MASK = "MGF1";
    public static final String VERIFY_ALGO_RSA = "SHA256withRSA";

    public static final String PUBLIC_KEY_START = "-----BEGIN PUBLIC KEY-----";
    public static final String PUBLIC_KEY_END = "-----END PUBLIC KEY-----";

    public static final String PRIVATE_KEY_START = "-----BEGIN PRIVATE KEY-----";
    public static final String PRIVATE_KEY_END = "-----END PRIVATE KEY-----";

    public static final String ROLE_PREFIX = "ROLE";
    public static final String MSGTYPE_PREFIX = "MSGTYPE";

    public static final String DATETIME_FORMAT = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    public static final String SWIFTBIC_FORMAT= "^[A-Z]{6}[A-Z0-9]{2}([A-Z0-9]{3})?$";

    public static final String CLIENT_KEY_ID_SUFFIX = "_CLIENT_RSA";
    public static final String NETWORK_KEY_ID_SUFFIX = "_PARTIOR_RSA";

    public static final String FILE_PUBLIC_KEY_EXTENSION = ".pem";
    public static final String FILE_PRIVATE_KEY_EXTENSION = ".pk8";

    public static final String HASHICORP_DECRYPT_PATH = "transit/decrypt/";
    public static final String HASHICORP_SIGN_PATH = "transit/sign/";
    public static final String HASHICORP_KV_PATH = "secret/data/verify/";
    public static final String HASHICORP_SIGNATURE_ALGORITHM = "pkcs1v15";

    public static final String MESSAGE_TYPE_NOT_ALLOWED_FOR_SYSTEM_ID = "Message type not allowed for system ID";
    public static final String DUPLICATE_MESSAGE_ID_FOR_SYSTEM_ID = "Duplicate message id for system id";
    public static final String SIGNATURE_VALIDATION_FAILED = "Signature validation failed";
    public static final String CONSTRAINT_VIOLATIONS = "Constraint violations";
    public static final String DECRYPTION_OR_SIGNATURE_VALIDATION_FAILED = "Decryption or signature validation failed";
    public static final String PAYLOAD_IS_NULL = "Payload is null";

    public static final String ACCESS_MANAGER_CLUSTER_ID = "/cluster/id";

}