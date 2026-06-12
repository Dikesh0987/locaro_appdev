class EmailTemplates {
  static String getWelcomeEmail() {
    return """
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif;
            background-color: #FAFAFA;
            color: #111827;
        }
        .container {
            max-width: 600px;
            margin: 40px auto;
            background-color: #FFFFFF;
            border-radius: 12px;
            overflow: hidden;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.05);
        }
        .header {
            background-color: #0B1736;
            padding: 40px 20px;
            text-align: center;
        }
        .header h1 {
            color: #FFFFFF;
            margin: 0;
            font-size: 28px;
            letter-spacing: 1px;
        }
        .content {
            padding: 40px 30px;
            text-align: center;
        }
        .success-icon {
            background-color: #10B981;
            color: white;
            width: 60px;
            height: 60px;
            border-radius: 50%;
            display: inline-flex;
            align-items: center;
            justify-content: center;
            font-size: 30px;
            margin-bottom: 20px;
        }
        h2 {
            color: #0B1736;
            margin-top: 0;
            font-size: 24px;
        }
        p {
            color: #6B7280;
            line-height: 1.6;
            font-size: 16px;
            margin-bottom: 25px;
        }
        .features {
            text-align: left;
            background-color: #F3F4F6;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
        }
        .feature-item {
            margin-bottom: 12px;
            color: #111827;
            font-weight: 500;
        }
        .feature-item span {
            color: #F97316;
            font-weight: bold;
            margin-right: 8px;
        }
        .button {
            display: inline-block;
            background-color: #F97316;
            color: #FFFFFF;
            text-decoration: none;
            padding: 14px 32px;
            border-radius: 8px;
            font-weight: bold;
            font-size: 16px;
            transition: background-color 0.3s;
        }
        .footer {
            background-color: #FAFAFA;
            padding: 20px;
            text-align: center;
            font-size: 12px;
            color: #9CA3AF;
            border-top: 1px solid #F3F4F6;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>LOCARO</h1>
        </div>
        <div class="content">
            <div class="success-icon">✓</div>
            <h2>Email Verified Successfully!</h2>
            <p>Welcome to Locaro! Your email address has been successfully verified and linked to your account. You are now fully set up to explore the best local merchants around you.</p>
            
            <div class="features">
                <div class="feature-item"><span>🚀</span> Discover hyperlocal products and deals</div>
                <div class="feature-item"><span>🏬</span> Connect directly with verified merchants</div>
                <div class="feature-item"><span>💬</span> Send queries and negotiate in real-time</div>
                <div class="feature-item"><span>🔔</span> Get notified about the latest drops near you</div>
            </div>

            <p>Ready to see what's happening in your neighborhood?</p>
            
            <a href="https://your-locaro-app-link.com" class="button">Explore Locaro Now</a>
        </div>
        <div class="footer">
            <p>© 2026 Locaro. All rights reserved.</p>
            <p>If you didn't request this verification, please ignore this email or contact support.</p>
        </div>
    </div>
</body>
</html>
    """;
  }
}
