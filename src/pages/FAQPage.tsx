import React, { useState } from 'react';
import { ArrowLeft, HelpCircle, ChevronDown, ChevronUp } from 'lucide-react';
import { useNavigate } from 'react-router-dom';

interface FAQItem {
  id: string;
  question: string;
  answer: string;
  category: string;
}

const FAQ_DATA: FAQItem[] = [
  {
    id: '1',
    question: 'What is TokenLaunch?',
    answer: 'TokenLaunch is a multi-chain token creation and trading platform that allows users to easily create, deploy, and trade tokens across various blockchain networks including Solana, Ethereum, Tron, BNB Chain, and Bitcoin.',
    category: 'General'
  },
  {
    id: '2',
    question: 'How do I create a token?',
    answer: 'To create a token, click the "Create Token" button in the header, fill out the token information (name, symbol, description, image), select your preferred network, and confirm the transaction. You\'ll need to have sufficient funds in your wallet to cover gas fees.',
    category: 'Token Creation'
  },
  {
    id: '3',
    question: 'What networks are supported?',
    answer: 'We currently support Solana (SOL), Ethereum (ETH), Tron (TRX), BNB Chain (BNB), and Bitcoin (BTC). Each network has different fees and characteristics.',
    category: 'Networks'
  },
  {
    id: '4',
    question: 'What are the fees for creating tokens?',
    answer: 'Fees vary by network: Solana (~0.1 SOL), Ethereum (varies with gas prices, typically $20-100), Tron (~100 TRX), BNB Chain (~0.01 BNB). These fees go to the network validators, not to TokenLaunch.',
    category: 'Fees'
  },
  {
    id: '5',
    question: 'How does the bonding curve work?',
    answer: 'The bonding curve is an automated market maker that determines token price based on supply. As more tokens are bought, the price increases. When the market cap reaches $1M, liquidity is deposited to DEXs and LP tokens are burned.',
    category: 'Trading'
  },
  {
    id: '6',
    question: 'What are live streams?',
    answer: 'Live streams allow token creators to broadcast live video content to promote their tokens and engage with the community. Viewers can chat, tip, and interact with streamers in real-time.',
    category: 'Live Streaming'
  },
  {
    id: '7',
    question: 'How do I buy tokens?',
    answer: 'Connect your wallet, find the token you want to buy, enter the amount you want to spend, and confirm the transaction. Make sure you have enough funds for the purchase plus gas fees.',
    category: 'Trading'
  },
  {
    id: '8',
    question: 'Can I sell my tokens anytime?',
    answer: 'Yes, you can sell your tokens anytime through the platform. The price you receive depends on the current bonding curve price and available liquidity.',
    category: 'Trading'
  },
  {
    id: '9',
    question: 'What happens if a token doesn\'t reach the market cap goal?',
    answer: 'Tokens that don\'t reach the $1M market cap goal remain on the bonding curve. They can still be traded, but won\'t have external DEX liquidity until the goal is reached.',
    category: 'Token Creation'
  },
  {
    id: '10',
    question: 'How do I connect my wallet?',
    answer: 'Click the wallet connect button and select your preferred wallet (MetaMask, Phantom, etc.). Make sure you\'re on the correct network for the tokens you want to interact with.',
    category: 'Wallet'
  },
  {
    id: '11',
    question: 'Is TokenLaunch safe to use?',
    answer: 'We implement security best practices including smart contract audits, secure infrastructure, and user education. However, DeFi involves risks - never invest more than you can afford to lose.',
    category: 'Security'
  },
  {
    id: '12',
    question: 'Can I create multiple tokens?',
    answer: 'Yes, there\'s no limit to how many tokens you can create. Each token creation requires separate network fees and must meet our content guidelines.',
    category: 'Token Creation'
  },
  {
    id: '13',
    question: 'What are the content guidelines for tokens?',
    answer: 'Tokens cannot infringe on intellectual property, promote illegal activities, contain hate speech, or be designed to scam users. We reserve the right to remove tokens that violate our guidelines.',
    category: 'Guidelines'
  },
  {
    id: '14',
    question: 'How do I report a problematic token?',
    answer: 'If you find a token that violates our guidelines or appears to be a scam, please contact our support team at support@tokenlaunch.com with details.',
    category: 'Support'
  },
  {
    id: '15',
    question: 'Can I get a refund?',
    answer: 'Due to the nature of blockchain transactions, refunds are generally not possible. All transactions are final once confirmed on the blockchain.',
    category: 'Support'
  }
];

export const FAQPage: React.FC = () => {
  const navigate = useNavigate();
  const [openItems, setOpenItems] = useState<Set<string>>(new Set());
  const [selectedCategory, setSelectedCategory] = useState<string>('All');

  const categories = ['All', ...Array.from(new Set(FAQ_DATA.map(item => item.category)))];

  const filteredFAQ = selectedCategory === 'All' 
    ? FAQ_DATA 
    : FAQ_DATA.filter(item => item.category === selectedCategory);

  const toggleItem = (id: string) => {
    const newOpenItems = new Set(openItems);
    if (newOpenItems.has(id)) {
      newOpenItems.delete(id);
    } else {
      newOpenItems.add(id);
    }
    setOpenItems(newOpenItems);
  };

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
            <HelpCircle className="h-6 w-6 text-green-400" />
            <h1 className="text-2xl font-bold text-white">Frequently Asked Questions</h1>
          </div>
        </div>
      </div>

      <div className="max-w-4xl mx-auto p-6">
        {/* Category Filter */}
        <div className="mb-8">
          <div className="flex flex-wrap gap-2">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-4 py-2 rounded-lg font-medium transition-colors ${
                  selectedCategory === category
                    ? 'bg-green-500 text-white'
                    : 'bg-gray-800 text-gray-300 hover:bg-gray-700'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>

        {/* FAQ Items */}
        <div className="space-y-4">
          {filteredFAQ.map((item) => (
            <div key={item.id} className="bg-gray-900 rounded-xl border border-gray-800">
              <button
                onClick={() => toggleItem(item.id)}
                className="w-full flex items-center justify-between p-6 text-left hover:bg-gray-800 transition-colors rounded-xl"
              >
                <div className="flex-1">
                  <div className="flex items-center space-x-3 mb-1">
                    <span className="text-sm text-green-400 font-medium">{item.category}</span>
                  </div>
                  <h3 className="text-lg font-semibold text-white">{item.question}</h3>
                </div>
                <div className="ml-4">
                  {openItems.has(item.id) ? (
                    <ChevronUp className="h-5 w-5 text-gray-400" />
                  ) : (
                    <ChevronDown className="h-5 w-5 text-gray-400" />
                  )}
                </div>
              </button>
              
              {openItems.has(item.id) && (
                <div className="px-6 pb-6">
                  <div className="border-t border-gray-800 pt-4">
                    <p className="text-gray-300 leading-relaxed">{item.answer}</p>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Contact Support */}
        <div className="mt-12 bg-gradient-to-r from-green-500/10 to-emerald-500/10 border border-green-500/20 rounded-xl p-6">
          <div className="text-center">
            <HelpCircle className="h-12 w-12 text-green-400 mx-auto mb-4" />
            <h3 className="text-xl font-bold text-white mb-2">Still have questions?</h3>
            <p className="text-gray-300 mb-4">
              Can't find the answer you're looking for? Our support team is here to help.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <a
                href="mailto:support@tokenlaunch.com"
                className="bg-green-500 hover:bg-green-600 text-white px-6 py-3 rounded-lg font-medium transition-colors"
              >
                Contact Support
              </a>
              <a
                href="https://discord.gg/tokenlaunch"
                target="_blank"
                rel="noopener noreferrer"
                className="bg-gray-800 hover:bg-gray-700 text-white px-6 py-3 rounded-lg font-medium transition-colors"
              >
                Join Discord
              </a>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};