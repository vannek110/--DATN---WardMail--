import React from 'react';
import { ArrowLeft, Shield } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export const PrivacyPage: React.FC = () => {
  const navigate = useNavigate();

  return (
    <div className="min-h-screen bg-gray-950">
      {/* Header */}
      <div className="bg-gray-900 border-b border-gray-800 p-4">
        <div className="max-w-4xl mx-auto flex items-center space-x-4">
          <button
            onClick={() => navigate('/')}
            className="text-gray-400 hover:text-white transition-colors"
          >
            <ArrowLeft className="h-6 w-6" />
          </button>
          <div className="flex items-center space-x-3">
            <Shield className="h-6 w-6 text-green-400" />
            <h1 className="text-2xl font-bold text-white">Privacy Policy</h1>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto p-6">
        <div className="bg-gray-900 rounded-xl p-8">
          <div className="prose prose-invert max-w-none">
            <p className="text-gray-400 mb-8">Last updated: January 2024</p>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">1. Information We Collect</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We collect information you provide directly to us, such as when you create an account, use our services, or contact us.
              </p>
              
              <h3 className="text-lg font-semibold text-white mb-3">Personal Information</h3>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Email address and account credentials</li>
                <li>Profile information (name, avatar)</li>
                <li>Wallet addresses and transaction history</li>
                <li>Communication preferences</li>
              </ul>

              <h3 className="text-lg font-semibold text-white mb-3">Usage Information</h3>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Platform usage patterns and preferences</li>
                <li>Trading activity and token interactions</li>
                <li>Chat messages and stream interactions</li>
                <li>Device information and IP addresses</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">2. How We Use Your Information</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We use the information we collect to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Provide, maintain, and improve our services</li>
                <li>Process transactions and manage your account</li>
                <li>Send you technical notices and support messages</li>
                <li>Detect and prevent fraud and abuse</li>
                <li>Comply with legal obligations</li>
                <li>Analyze usage patterns to improve user experience</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">3. Information Sharing</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We do not sell, trade, or otherwise transfer your personal information to third parties except in the following circumstances:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>With your explicit consent</li>
                <li>To comply with legal obligations</li>
                <li>To protect our rights and prevent fraud</li>
                <li>With service providers who assist in platform operations</li>
                <li>In connection with a business transfer or merger</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">4. Blockchain Transparency</h2>
              <div className="bg-blue-500/10 border border-blue-500/20 rounded-lg p-4 mb-4">
                <p className="text-blue-200 font-medium mb-2">🔗 Blockchain Notice</p>
                <p className="text-blue-300 text-sm">
                  Please note that blockchain transactions are public and permanent. 
                  Token creation, trading, and other blockchain activities may be visible to anyone.
                </p>
              </div>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">5. Data Security</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We implement appropriate security measures to protect your information:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Encryption of sensitive data in transit and at rest</li>
                <li>Regular security audits and monitoring</li>
                <li>Access controls and authentication measures</li>
                <li>Secure infrastructure and hosting</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">6. Your Rights</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                You have the right to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Access and update your personal information</li>
                <li>Delete your account and associated data</li>
                <li>Opt out of marketing communications</li>
                <li>Request a copy of your data</li>
                <li>File complaints with data protection authorities</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">7. Cookies and Tracking</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We use cookies and similar technologies to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Remember your preferences and settings</li>
                <li>Analyze platform usage and performance</li>
                <li>Provide personalized content and features</li>
                <li>Prevent fraud and enhance security</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">8. Children's Privacy</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                Our service is not intended for children under 18 years of age. 
                We do not knowingly collect personal information from children under 18.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">9. Changes to Privacy Policy</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We may update this privacy policy from time to time. 
                We will notify you of any changes by posting the new policy on this page.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">10. Contact Us</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                If you have any questions about this Privacy Policy, please contact us:
              </p>
              <div className="bg-gray-800 rounded-lg p-4">
                <p className="text-white">Email: privacy@tokenlaunch.com</p>
                <p className="text-white">Support: support@tokenlaunch.com</p>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};