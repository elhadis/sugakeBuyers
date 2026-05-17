const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

if (!admin.apps.length) {
  admin.initializeApp();
}

/**
 * Triggered only when a NEW document is created in `items/{itemId}`.
 * Sends a high-priority push notification with data payload:
 * - itemImage
 * - itemPrice
 * - storeName
 * - ownerPhone
 */
exports.notifyOnNewItem = onDocumentCreated(
    {
      document: "items/{itemId}",
      region: "us-central1",
    },
    async (event) => {
      try {
        const snapshot = event.data;
        if (!snapshot) {
          logger.warn("No snapshot data found in onDocumentCreated event.");
          return;
        }

        const itemData = snapshot.data() || {};
        const itemId = String(event.params.itemId || snapshot.id || "");
        // App writes thumbnailUrl (upload_items_screen); keep legacy keys.
        const thumbnailUrl = String(
            itemData.thumbnailUrl ||
            itemData.thumbanilurl ||
            itemData.itemImage ||
            itemData.imageUrl ||
            "",
        ).trim();
        const itemImage = thumbnailUrl;
        const itemTitle = String(
            itemData.itemTitle || itemData.temTitle || "New Item",
        );
        const itemPrice = String(itemData.itemPrice || "");
        const storeName = String(itemData.sellerName || "Store");
        const brandName = String(itemData.brandName || storeName || "Brand");
        const ownerPhone = String(itemData.sellerPhone || "");
        const sellerPhone = ownerPhone;
        const currency = String(
            itemData.currency || itemData.addressCurrency || "₪",
        );

        /** @type {{title: string, body: string, image?: string}} */
        const notification = {
          title: "New Item Added",
          body: `${storeName} added ${itemTitle} at ${itemPrice}`,
        };
        if (thumbnailUrl) {
          notification.image = thumbnailUrl;
        }

        /** @type {import("firebase-admin").messaging.Message} */
        const message = {
          topic: "new_items",
          notification,
          data: {
            itemId,
            itemTitle,
            thumbnailUrl,
            itemImage,
            imageUrl: thumbnailUrl,
            itemPrice,
            currency,
            storeName,
            brandName,
            ownerPhone,
            sellerPhone,
            click_action: "FLUTTER_NOTIFICATION_CLICK",
          },
          android: {
            priority: "high",
            notification: {
              channelId: "new_item_high_importance_channel",
              sound: "default",
              defaultSound: true,
              ...(thumbnailUrl ? {imageUrl: thumbnailUrl} : {}),
            },
          },
          apns: {
            headers: {
              "apns-priority": "10",
            },
            payload: {
              aps: {
                sound: "default",
                contentAvailable: true,
                mutableContent: true,
              },
            },
            ...(thumbnailUrl ?
              {fcm_options: {image: thumbnailUrl}} :
              {}),
          },
        };

        const response = await admin.messaging().send(message);
        logger.info(
            "Push notification sent successfully",
            {messageId: response},
        );
      } catch (error) {
        logger.error("Failed to send push notification for new item", error);
      }
    },
);
