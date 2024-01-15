# DCTRL Membership and Fob 

This project contains the smart contract and local testing tool for DCTRL Membership.

https://app.dework.xyz/dctrl/nft-membership-40303/view/board-loywtdc1?taskId=225389bb-682e-4954-83e6-461c3adffc10

Userflow state diagrams: https://miro.com/app/board/uXjVN9-cSjo=/?share_link_id=748410878407

## Deployments
FobNFT Optimism-Sepolia: https://optimism-sepolia.blockscout.com/address/0x93f6A58CeB439fbe8DDa84B5E02e334aaF6024c4

# How to use
1. Create a copy of `.env.example` and rename it to `.env`
2. Add your private key to `.env` if you intend to deploy
3. Install with `npm install`

4. Use the DCTRL tool with `npm start` or `npx hardhat run .\scripts\start.js`

5. Deploy onchain with `npx hardhat run .\scripts\deploy\deploy.js`

There currently are no tests


You can create a long-running local hardhat node with `npx hardhat node` and then point the DCTRL tool to it with `npx hardhat run .\scripts\start.js --network hardhat` and pointing your dApp to `localhost:8545` with `chainId 31337`

## DCTRL Tool
This is a command line tool for interacting with a local deployment of the smart contracts.

Run it with `npm start`

To see a tutorial, watch the following 13 min video (i know the link looks sus, but it's a microsoft [.ms] onedrive [1drv] link): https://1drv.ms/v/s!AiBtiJ6tWLolzA3UwNhtoc5Wp9Pp?e=Ykq630

## Smart Contracts
### Summary
This project contains the following smart contracts:
- MembershipNFT.sol
- FobNFT.sol
- Minter.sol
- /TokenBound/* (ERC6551)

The DCTRL membership is built ontop of ERC6551: Non-fungible Token Bound Accounts
- https://eips.ethereum.org/EIPS/eip-6551
- https://tokenbound.org/
- https://github.com/erc6551/reference
- https://github.com/tokenbound

The idea is that each human being that joins DCTRL gets a "soulbound" MembershipNFT. The MembershipNFT can hold a FobNFT that corresponds to a real physical fob that gives access to the physical space. 

All contracts are managed via AccessControl roles.

The multisig is expected to always have superadmin rights.

### MembershipNFT
MembershipNFT.sol is an ERC721 that contains two fields:
- creationDate
- name

The NFT is meant intended to be a 1:1 lifetime onchain representation with each physical human being. The NFT is "soulbound" in the sense that it cannot be traded by default.

The MembershipNFT is expected to be upgraded to a TokenBoundAccount using AccountV3. This way, the MembershipNFT can hold additional NFTs and scale to additional onchain activities.

### FobNFT
FobNFT.sol is an ERC721 that represents a physical fob that gives access to the DCTRL space. It is intended that either EOA or a TokenBoundAccount can hold a fob.

The Expiration of the Fob is UNIX time in seconds and can be queried via `tokenURI()` or `idToExpiration()`.

### Minter
Minter.sol is the orcestrator contract that users interact with. It is expected to have the roles to issue and manage membershipNFTs and fobNFTs. Minter is also expected to handle payment.

### /TokenBound/*
These are a copy of the ERC6551 Registry (https://github.com/erc6551/reference) and AccountV3 (https://github.com/tokenbound/contracts) contracts. This is used for local testing only. It is expected that we use the existing onchain Registry in production per the ERC6551 spec.

### Tests
Test suite is in Foundry, install docs here (https://book.getfoundry.sh/getting-started/installation)

One environment variable `RPC_NODE_URL` must be set in .env, because the tests require forking from latest block on that chain **at this time**.

To run tests:
`forge test -v`

