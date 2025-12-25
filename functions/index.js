// ----------------------------------------------------------------------
// 1. MODULE IMPORTS (Using V2 Modular API)
// ----------------------------------------------------------------------
const {onCall} = require("firebase-functions/v2/https");
const {setGlobalOptions} = require("firebase-functions/v2");
const {defineSecret} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");

// Third-party dependencies
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const admin = require('firebase-admin');

// Initialize Firebase Admin SDK
admin.initializeApp();


// ----------------------------------------------------------------------
// 2. CONFIGURATION AND SECRETS
// ----------------------------------------------------------------------

// Define the secrets. These names MUST match the keys you set via the CLI.
// To set these secrets, run:
// firebase functions:secrets:set AGORA_APP_ID
// firebase functions:secrets:set AGORA_APP_CERTIFICATE
const AGORA_APP_ID = defineSecret('AGORA_APP_ID');
const AGORA_APP_CERTIFICATE = defineSecret('AGORA_APP_CERTIFICATE');

// Set the token expiry time (e.g., 3600 seconds = 1 hour)
const EXPIRATION_TIME_IN_SECONDS = 3600;

// Set global options for all V2 functions
setGlobalOptions({
    maxInstances: 10,
    // It is a best practice to set a region globally for cost and latency
    // region: 'us-central1'
});


// ----------------------------------------------------------------------
// 3. AGORA TOKEN GENERATION FUNCTION (HTTPS ON CALL)
// ----------------------------------------------------------------------

/**
 * Generates an Agora RTC Token using Firebase Authentication for security.
 * The client must be authenticated to call this function.
 */
exports.generateAgoraToken = onCall({
    // Securely make the secrets available to this function instance
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
}, async (request) => {

    // 1. Authentication and Input Validation
    if (!request.auth) {
        logger.error('Request rejected: Unauthenticated call.', { auth: request.auth });
        throw new functions.https.HttpsError('unauthenticated',
            'The function must be called while authenticated.');
    }

    const channelName = request.data.channelName;
    const uid = request.data.uid || 0;

    if (!channelName) {
        logger.error('Request rejected: Missing channelName.', { data: request.data });
        throw new functions.https.HttpsError('invalid-argument',
            'Missing channel name in request data.');
    }

    // Access the secret values (only accessible because they are listed in 'secrets' array)
    const appId = AGORA_APP_ID.value();
    const appCertificate = AGORA_APP_CERTIFICATE.value();

    if (!appId || !appCertificate) {
        logger.error('Server Configuration Error: Missing Agora credentials.');
        throw new functions.https.HttpsError('internal',
            'Server configuration error: Agora credentials not set.');
    }

    // 2. Token Parameters
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + EXPIRATION_TIME_IN_SECONDS;

    // The role is Publisher (can send and receive streams)
    const role = RtcRole.PUBLISHER;

    // 3. Generate the Token
    try {
        const token = RtcTokenBuilder.buildTokenWithUid(
            appId,
            appCertificate,
            channelName,
            uid,
            role,
            privilegeExpiredTs
        );

        logger.info(`Token generated for channel: ${channelName}, UID: ${uid}`);

        return { token: token };

    } catch (error) {
        logger.error("Token generation failed:", error);
        throw new functions.https.HttpsError('internal',
            'Failed to generate token due to an internal server error.');
    }
});

// The commented-out V1 function has been removed to avoid conflict.
// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

// The V1 'onRequest' import has also been removed.