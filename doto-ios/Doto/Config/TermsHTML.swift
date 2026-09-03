import Foundation

enum TermsHTML {
    static let content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Terms of Service — Doto</title>
    <style>
      body {
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
        max-width: 760px;
        margin: 0 auto;
        padding: 24px 24px 60px;
        color: #1E293B;
        line-height: 1.7;
      }
      h1 {
        color: #1E2761;
        font-size: 28px;
        margin-bottom: 4px;
      }
      .updated {
        color: #64748B;
        font-size: 14px;
        margin-bottom: 32px;
      }
      h2 {
        color: #1E2761;
        font-size: 20px;
        margin-top: 32px;
        border-bottom: 2px solid #EFF6FF;
        padding-bottom: 8px;
      }
      h3 {
        color: #185FA5;
        font-size: 16px;
        margin-top: 20px;
      }
      a { color: #185FA5; }
      ul { padding-left: 24px; }
      li { margin-bottom: 8px; }
      .highlight-box {
        background: #EFF6FF;
        border-left: 4px solid #185FA5;
        padding: 16px 20px;
        border-radius: 6px;
        margin: 24px 0;
      }
      .contact-box {
        background: #F8FAFC;
        border-radius: 8px;
        padding: 20px;
        margin-top: 32px;
      }
    </style>
    </head>
    <body>

    <h1>Terms of Service</h1>
    <p class="updated">Last updated: September 3, 2026</p>

    <p>Welcome to Doto. These Terms of Service ("Terms") govern your access to and use of the Doto mobile application (the "App"), operated by Doto ("we," "our," or "us"). By creating an account or using the App, you agree to these Terms. If you do not agree, please do not use the App.</p>

    <div class="highlight-box">
    <strong>The short version:</strong> Doto is a family coordination app. Parents create the family account and are responsible for their family's use of the app, including any child accounts. Subscriptions renew automatically unless cancelled, and are billed through your Apple ID. Please use Doto respectfully and don't try to break it.
    </div>

    <h2>1. Eligibility and Accounts</h2>
    <ul>
      <li>You must be at least 18 years old to create a parent/family account. By creating an account, you represent that you are legally able to enter into these Terms.</li>
      <li>Parents are responsible for setting up and managing child accounts within their family, and for supervising their children's use of the App.</li>
      <li>You are responsible for keeping your login credentials secure. Notify us immediately if you suspect unauthorized access to your account.</li>
      <li>You agree to provide accurate information when creating your account and to keep it up to date.</li>
    </ul>

    <h2>2. Family Accounts and Content</h2>
    <ul>
      <li>A "family" in Doto consists of one or more parent accounts and any number of linked child accounts, joined via a private family invite code.</li>
      <li>Content created within the App — tasks, schedules, shopping lists, and reward activity — is owned by the family that created it and is only visible to members of that family group.</li>
      <li>Parents may add, edit, or remove child accounts and their content at any time.</li>
      <li>You agree not to use the App to store or share content that is unlawful, harassing, abusive, or otherwise inappropriate.</li>
    </ul>

    <h2>3. Subscriptions and Payment</h2>
    <h3>Free Trial</h3>
    <p>New accounts receive a 30-day free trial with full access to Doto's features. No payment is required to start the trial.</p>

    <h3>Subscription Plans</h3>
    <p>After the free trial ends, continued use of Doto requires an active paid subscription:</p>
    <ul>
      <li><strong>Monthly:</strong> $3.99/month</li>
      <li><strong>Annual:</strong> $29.99/year</li>
    </ul>

    <h3>Billing</h3>
    <ul>
      <li>Subscriptions are billed through your Apple ID account and processed via Apple's In-App Purchase system.</li>
      <li>Subscriptions automatically renew at the end of each billing period unless cancelled at least 24 hours before the renewal date.</li>
      <li>Your Apple ID account will be charged for renewal within 24 hours prior to the end of the current period.</li>
      <li>You can manage or cancel your subscription anytime in your device's Settings → [Your Name] → Subscriptions.</li>
      <li>No refunds are provided for partial subscription periods, except as required by applicable law or Apple's refund policies.</li>
    </ul>

    <h3>Price Changes</h3>
    <p>We may change subscription pricing from time to time. If prices change, we will provide notice before the change takes effect, and continued use of the App after a price change constitutes acceptance of the new pricing.</p>

    <h2>4. Acceptable Use</h2>
    <p>You agree not to:</p>
    <ul>
      <li>Use the App for any unlawful purpose</li>
      <li>Attempt to gain unauthorized access to other users' accounts or family data</li>
      <li>Reverse engineer, decompile, or attempt to extract the source code of the App</li>
      <li>Use automated systems (bots, scrapers) to access the App</li>
      <li>Interfere with or disrupt the App's servers or infrastructure</li>
      <li>Impersonate another person or family</li>
    </ul>

    <h2>5. Children's Use of the App</h2>
    <p>Child accounts are intended to be created and supervised by a parent or legal guardian. Parents are responsible for reviewing their child's activity within the App and for ensuring their child's use complies with these Terms. See our <a href="https://www.dotofamily.com/privacy">Privacy Policy</a> for details on how we handle children's information in compliance with COPPA.</p>

    <h2>6. Location Sharing</h2>
    <p>Doto's optional location features ("Where are you?" and "I'm on my way") share a one-time GPS location only when actively initiated by a parent or child. By using these features, you consent to that location being shared with members of your family group. You may choose not to use these features at any time.</p>

    <h2>7. Intellectual Property</h2>
    <p>The App, including its design, logo, features, and underlying software, is owned by Doto and protected by copyright and other intellectual property laws. These Terms do not grant you any ownership rights in the App — only a limited, non-transferable license to use it for personal, family purposes.</p>

    <h2>8. Termination</h2>
    <ul>
      <li>You may delete your account at any time through the App's Settings.</li>
      <li>We reserve the right to suspend or terminate accounts that violate these Terms, engage in abusive behavior, or pose a risk to other users.</li>
      <li>Upon termination, your right to use the App ends immediately. Sections of these Terms that by their nature should survive termination (such as intellectual property and limitation of liability) will continue to apply.</li>
    </ul>

    <h2>9. Disclaimers</h2>
    <p>The App is provided "as is" and "as available," without warranties of any kind, whether express or implied. We do not guarantee that the App will be uninterrupted, error-free, or completely secure. Doto is a coordination and organizational tool; we are not responsible for missed events, incomplete tasks, or any consequences arising from reliance on the App's scheduling, reminders, or location features.</p>

    <h2>10. Limitation of Liability</h2>
    <p>To the fullest extent permitted by law, Doto and its operators shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of, or inability to use, the App. Our total liability for any claim relating to the App shall not exceed the amount you paid us in the twelve (12) months prior to the claim.</p>

    <h2>11. Changes to These Terms</h2>
    <p>We may update these Terms from time to time. If we make material changes, we will provide notice through the App or by other reasonable means. Continued use of the App after changes take effect constitutes your acceptance of the updated Terms.</p>

    <h2>12. Governing Law</h2>
    <p>These Terms are governed by the laws of the United States and the State of California, without regard to conflict of law principles, unless otherwise required by the laws of your country of residence.</p>

    <h2>13. Contact Us</h2>
    <div class="contact-box">
    <p>If you have questions about these Terms, please contact us:</p>
    <p>
      <strong>Email:</strong> <a href="mailto:support@dotofamily.com">support@dotofamily.com</a><br>
      <strong>Website:</strong> <a href="https://www.dotofamily.com">https://www.dotofamily.com</a>
    </p>
    </div>

    </body>
    </html>
    """
}
