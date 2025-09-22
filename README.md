BondForge
A decentralized bond issuance and redemption system built with Clarity on the Stacks blockchain.
It enables on-chain creation, purchase, and redemption of tokenized bonds backed by STX or SIP-010 tokens.

Features
Issue new bonds with maturity date and fixed interest rate
Users can purchase bonds with STX or fungible tokens
Bonds accrue interest until maturity
Redeem bonds for principal + interest after maturity
On-chain event logs for transparency

Technical Overview
Language: Clarity
Core Functions:
issue-bond – create a new bond series
buy-bond – purchase bond with STX or token
redeem-bond – claim principal + interest after maturity
get-bond-info – view bond details

Installation & Usage
Clone repository:
git clone https://github.com/your-repo/bondforge.git
cd bondforge
Deploy with Clarinet:
clarinet contract deploy bondforge
Run tests:
clarinet test

Roadmap
Add secondary bond trading (P2P transfers)
Support floating interest rates
DAO-managed issuance rules
Multi-token collateral support
