import React from 'react';
import { ArrowLeft, FileText } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

export const TermsPage: React.FC = () => {
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
            <FileText className="h-6 w-6 text-green-400" />
            <h1 className="text-2xl font-bold text-white">Terms of Service</h1>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto p-6">
        <div className="bg-gray-900 rounded-xl p-8">
          <div className="prose prose-invert max-w-none">
            <p className="text-gray-400 mb-8">Last updated: January 2024</p>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">1. Acceptance of Terms</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                By accessing and using TokenLaunch, you accept and agree to be bound by the terms and provision of this agreement. 
                If you do not agree to abide by the above, please do not use this service.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">2. Description of Service</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                TokenLaunch is a multi-chain token creation and trading platform that allows users to:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Create and deploy tokens on various blockchain networks</li>
                <li>Trade tokens through our platform</li>
                <li>Participate in live streaming and community features</li>
                <li>Access real-time market data and analytics</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">3. User Responsibilities</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                Users are responsible for:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Maintaining the security of their account credentials</li>
                <li>Complying with all applicable laws and regulations</li>
                <li>Not engaging in fraudulent or manipulative activities</li>
                <li>Respecting intellectual property rights</li>
                <li>Not creating tokens that violate our content policy</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">4. Risk Disclosure</h2>
              <div className="bg-orange-500/10 border border-orange-500/20 rounded-lg p-4 mb-4">
                <p className="text-orange-200 font-medium mb-2">⚠️ Important Risk Warning</p>
                <p className="text-orange-300 text-sm">
                  Trading cryptocurrencies and tokens involves substantial risk of loss and is not suitable for all investors. 
                  You should carefully consider whether trading is suitable for you in light of your circumstances, knowledge, and financial resources.
                </p>
              </div>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Token values can be extremely volatile</li>
                <li>You may lose all or part of your investment</li>
                <li>Past performance does not guarantee future results</li>
                <li>Regulatory changes may affect token values</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">5. Prohibited Activities</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                The following activities are strictly prohibited:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Market manipulation or pump and dump schemes</li>
                <li>Creating tokens that infringe on intellectual property</li>
                <li>Harassment or abusive behavior in chat or streams</li>
                <li>Attempting to hack or exploit the platform</li>
                <li>Money laundering or other illegal financial activities</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">6. Platform Fees</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                TokenLaunch charges fees for various services:
              </p>
              <ul className="list-disc list-inside text-gray-300 space-y-2 mb-4">
                <li>Token creation fees (varies by network)</li>
                <li>Trading fees (typically 0.5-1% per transaction)</li>
                <li>Network gas fees (paid to blockchain validators)</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">7. Limitation of Liability</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                TokenLaunch shall not be liable for any direct, indirect, incidental, special, consequential, or punitive damages 
                resulting from your use of the platform, including but not limited to trading losses, technical failures, or security breaches.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">8. Modifications to Terms</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                We reserve the right to modify these terms at any time. Users will be notified of significant changes, 
                and continued use of the platform constitutes acceptance of the modified terms.
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-xl font-bold text-white mb-4">9. Contact Information</h2>
              <p className="text-gray-300 leading-relaxed mb-4">
                If you have any questions about these Terms of Service, please contact us at:
              </p>
              <div className="bg-gray-800 rounded-lg p-4">
                <p className="text-white">Email: legal@tokenlaunch.com</p>
                <p className="text-white">Support: support@tokenlaunch.com</p>
              </div>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};