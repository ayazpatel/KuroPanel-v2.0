<?php

namespace App\Controllers;

use App\Models\UserModel;
use App\Models\LicenseKeyModel;
use App\Models\AppModel;

class Webhook extends BaseController
{
    protected $userModel;
    protected $licenseKeyModel;
    protected $appModel;

    public function __construct()
    {
        $this->userModel = new UserModel();
        $this->licenseKeyModel = new LicenseKeyModel();
        $this->appModel = new AppModel();
    }

    /**
     * Handle payment webhook notifications
     */
    public function payment()
    {
        // Get raw POST data
        $payload = $this->request->getBody();
        $headers = $this->request->getHeaders();

        // Log the webhook for debugging
        log_message('info', 'Payment webhook received: ' . $payload);

        try {
            $data = json_decode($payload, true);

            if (!$data) {
                log_message('error', 'Invalid JSON in payment webhook');
                return $this->response->setStatusCode(400)->setJSON(['error' => 'Invalid JSON']);
            }

            // Verify webhook signature if required
            // $this->verifyWebhookSignature($payload, $headers);

            // Process payment based on provider
            $provider = $data['provider'] ?? 'unknown';

            switch ($provider) {
                case 'paypal':
                    return $this->handlePayPalWebhook($data);
                case 'stripe':
                    return $this->handleStripeWebhook($data);
                case 'razorpay':
                    return $this->handleRazorpayWebhook($data);
                default:
                    log_message('warning', 'Unknown payment provider: ' . $provider);
                    return $this->response->setStatusCode(400)->setJSON(['error' => 'Unknown provider']);
            }

        } catch (\Exception $e) {
            log_message('error', 'Payment webhook error: ' . $e->getMessage());
            return $this->response->setStatusCode(500)->setJSON(['error' => 'Internal server error']);
        }
    }

    /**
     * Handle Telegram bot webhook notifications
     */
    public function telegram()
    {
        // Get raw POST data
        $payload = $this->request->getBody();
        
        // Log the webhook for debugging
        log_message('info', 'Telegram webhook received: ' . $payload);

        try {
            $data = json_decode($payload, true);

            if (!$data) {
                log_message('error', 'Invalid JSON in telegram webhook');
                return $this->response->setStatusCode(400)->setJSON(['error' => 'Invalid JSON']);
            }

            // Process telegram update
            if (isset($data['message'])) {
                return $this->handleTelegramMessage($data['message']);
            }

            if (isset($data['callback_query'])) {
                return $this->handleTelegramCallback($data['callback_query']);
            }

            return $this->response->setJSON(['status' => 'ok']);

        } catch (\Exception $e) {
            log_message('error', 'Telegram webhook error: ' . $e->getMessage());
            return $this->response->setStatusCode(500)->setJSON(['error' => 'Internal server error']);
        }
    }

    /**
     * Handle PayPal webhook
     */
    private function handlePayPalWebhook($data)
    {
        // Implement PayPal-specific logic
        $eventType = $data['event_type'] ?? '';
        
        switch ($eventType) {
            case 'PAYMENT.CAPTURE.COMPLETED':
                return $this->processPaymentCompleted($data, 'paypal');
            case 'PAYMENT.CAPTURE.DENIED':
                return $this->processPaymentFailed($data, 'paypal');
            default:
                log_message('info', 'Unhandled PayPal event: ' . $eventType);
                return $this->response->setJSON(['status' => 'ok']);
        }
    }

    /**
     * Handle Stripe webhook
     */
    private function handleStripeWebhook($data)
    {
        // Implement Stripe-specific logic
        $eventType = $data['type'] ?? '';
        
        switch ($eventType) {
            case 'payment_intent.succeeded':
                return $this->processPaymentCompleted($data, 'stripe');
            case 'payment_intent.payment_failed':
                return $this->processPaymentFailed($data, 'stripe');
            default:
                log_message('info', 'Unhandled Stripe event: ' . $eventType);
                return $this->response->setJSON(['status' => 'ok']);
        }
    }

    /**
     * Handle Razorpay webhook
     */
    private function handleRazorpayWebhook($data)
    {
        // Implement Razorpay-specific logic
        $event = $data['event'] ?? '';
        
        switch ($event) {
            case 'payment.captured':
                return $this->processPaymentCompleted($data, 'razorpay');
            case 'payment.failed':
                return $this->processPaymentFailed($data, 'razorpay');
            default:
                log_message('info', 'Unhandled Razorpay event: ' . $event);
                return $this->response->setJSON(['status' => 'ok']);
        }
    }

    /**
     * Process successful payment
     */
    private function processPaymentCompleted($data, $provider)
    {
        // Extract order/payment information
        $orderId = $this->extractOrderId($data, $provider);
        $amount = $this->extractAmount($data, $provider);
        
        // Update user balance or license status
        // This is a simplified implementation
        log_message('info', "Payment completed: Order {$orderId}, Amount {$amount}, Provider {$provider}");
        
        return $this->response->setJSON(['status' => 'processed']);
    }

    /**
     * Process failed payment
     */
    private function processPaymentFailed($data, $provider)
    {
        // Extract order/payment information
        $orderId = $this->extractOrderId($data, $provider);
        
        // Handle failed payment
        log_message('warning', "Payment failed: Order {$orderId}, Provider {$provider}");
        
        return $this->response->setJSON(['status' => 'failed']);
    }

    /**
     * Handle Telegram message
     */
    private function handleTelegramMessage($message)
    {
        $text = $message['text'] ?? '';
        $chatId = $message['chat']['id'] ?? 0;
        
        // Simple command handling
        if ($text === '/start') {
            $this->sendTelegramMessage($chatId, 'Welcome to KuroPanel! Use /help for available commands.');
        } elseif ($text === '/help') {
            $helpText = "Available commands:\n";
            $helpText .= "/start - Start the bot\n";
            $helpText .= "/help - Show this help message\n";
            $helpText .= "/status - Check system status";
            
            $this->sendTelegramMessage($chatId, $helpText);
        } elseif ($text === '/status') {
            $this->sendTelegramMessage($chatId, 'KuroPanel is running normally.');
        }
        
        return $this->response->setJSON(['status' => 'ok']);
    }

    /**
     * Handle Telegram callback query
     */
    private function handleTelegramCallback($callbackQuery)
    {
        $data = $callbackQuery['data'] ?? '';
        $chatId = $callbackQuery['message']['chat']['id'] ?? 0;
        
        // Handle callback data
        log_message('info', "Telegram callback: {$data} from chat {$chatId}");
        
        return $this->response->setJSON(['status' => 'ok']);
    }

    /**
     * Extract order ID from webhook data
     */
    private function extractOrderId($data, $provider)
    {
        switch ($provider) {
            case 'paypal':
                return $data['resource']['id'] ?? 'unknown';
            case 'stripe':
                return $data['data']['object']['id'] ?? 'unknown';
            case 'razorpay':
                return $data['payload']['payment']['entity']['order_id'] ?? 'unknown';
            default:
                return 'unknown';
        }
    }

    /**
     * Extract amount from webhook data
     */
    private function extractAmount($data, $provider)
    {
        switch ($provider) {
            case 'paypal':
                return $data['resource']['amount']['value'] ?? 0;
            case 'stripe':
                return ($data['data']['object']['amount'] ?? 0) / 100; // Convert cents to dollars
            case 'razorpay':
                return ($data['payload']['payment']['entity']['amount'] ?? 0) / 100; // Convert paise to rupees
            default:
                return 0;
        }
    }

    /**
     * Send message via Telegram bot
     */
    private function sendTelegramMessage($chatId, $message)
    {
        $botToken = env('TELEGRAM_BOT_TOKEN');
        
        if (empty($botToken)) {
            log_message('warning', 'Telegram bot token not configured');
            return false;
        }
        
        $url = "https://api.telegram.org/bot{$botToken}/sendMessage";
        
        $data = [
            'chat_id' => $chatId,
            'text' => $message,
            'parse_mode' => 'HTML'
        ];
        
        // Send request to Telegram API
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, $url);
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        
        $response = curl_exec($ch);
        curl_close($ch);
        
        return $response !== false;
    }
}
