export class NotificationService {
  static async sendNotification(event: string, details: string): Promise<boolean> {
    console.log(`[Notification] [${event}] Dispatched alert: ${details}`);

    const slackWebhook = process.env.NOTIFICATION_SLACK_WEBHOOK;
    const discordWebhook = process.env.NOTIFICATION_DISCORD_WEBHOOK;
    const telegramBotToken = process.env.NOTIFICATION_TELEGRAM_TOKEN;
    const telegramChatId = process.env.NOTIFICATION_TELEGRAM_CHAT_ID;
    const genericWebhook = process.env.NOTIFICATION_GENERIC_WEBHOOK;

    let success = true;

    // 1. Slack Webhook Dispatch
    if (slackWebhook) {
      try {
        const res = await fetch(slackWebhook, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            text: `⚠️ *[NEOS Platform Alert]*\n*Event:* ${event}\n*Details:* ${details}\n*Timestamp:* ${new Date().toISOString()}`
          })
        });
        if (!res.ok) success = false;
      } catch (err) {
        success = false;
        console.error("Slack Notification Error:", err);
      }
    }

    // 2. Discord Webhook Dispatch
    if (discordWebhook) {
      try {
        const res = await fetch(discordWebhook, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            content: `🚨 **[NEOS Platform Alert]**\n**Event:** ${event}\n**Details:** ${details}\n**Timestamp:** ${new Date().toISOString()}`
          })
        });
        if (!res.ok) success = false;
      } catch (err) {
        success = false;
        console.error("Discord Notification Error:", err);
      }
    }

    // 3. Telegram Message Dispatch
    if (telegramBotToken && telegramChatId) {
      try {
        const url = `https://api.telegram.org/bot${telegramBotToken}/sendMessage`;
        const res = await fetch(url, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            chat_id: telegramChatId,
            text: `🚨 [NEOS Platform Alert]\nEvent: ${event}\nDetails: ${details}\nTime: ${new Date().toISOString()}`
          })
        });
        if (!res.ok) success = false;
      } catch (err) {
        success = false;
        console.error("Telegram Notification Error:", err);
      }
    }

    // 4. Generic Webhook Dispatch
    if (genericWebhook) {
      try {
        const res = await fetch(genericWebhook, {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            event,
            details,
            timestamp: new Date().toISOString()
          })
        });
        if (!res.ok) success = false;
      } catch (err) {
        success = false;
        console.error("Generic Webhook Notification Error:", err);
      }
    }

    return success;
  }
}
