---
name: smart-contract-generator
description: Generates Solidity smart contracts with security best practices (ERC-20, ERC-721, ERC-1155, custom). Use when user asks to "create smart contract", "solidity contract", "erc20 token", "nft contract", or "web3 contract".
allowed-tools: [Write, Read]
---

# Smart Contract Template Generator

Generates secure Solidity smart contracts following OpenZeppelin standards and best practices.

## When to Use

- "Create an ERC-20 token"
- "Generate NFT contract"
- "Smart contract template"
- "Solidity contract with security"
- "Create DAO contract"

## Instructions

### 1. Determine Contract Type

Ask user which type:
- ERC-20 (Fungible Token)
- ERC-721 (NFT - Non-Fungible Token)
- ERC-1155 (Multi-Token)
- ERC-4626 (Tokenized Vault)
- Custom contract

### 2. Generate Contracts

## ERC-20 Token

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract MyToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable, ERC20Permit {
    constructor(address initialOwner)
        ERC20("MyToken", "MTK")
        Ownable(initialOwner)
        ERC20Permit("MyToken")
    {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    // Required override
    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }
}
```

## ERC-721 NFT

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract MyNFT is ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Pausable, Ownable, ERC721Burnable {
    uint256 private _nextTokenId;
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MINT_PRICE = 0.05 ether;

    constructor(address initialOwner)
        ERC721("MyNFT", "MNFT")
        Ownable(initialOwner)
    {}

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri) public payable {
        require(_nextTokenId < MAX_SUPPLY, "Max supply reached");
        require(msg.value >= MINT_PRICE, "Insufficient payment");

        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    // Required overrides
    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
```

## ERC-1155 Multi-Token

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Pausable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract MyMultiToken is ERC1155, Ownable, ERC1155Pausable, ERC1155Supply {
    constructor(address initialOwner)
        ERC1155("https://api.example.com/token/{id}.json")
        Ownable(initialOwner)
    {}

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    // Required overrides
    function _update(address from, address to, uint256[] memory ids, uint256[] memory values)
        internal
        override(ERC1155, ERC1155Pausable, ERC1155Supply)
    {
        super._update(from, to, ids, values);
    }
}
```

### 3. Security Patterns

**Reentrancy Protection:**
```solidity
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SecureContract is ReentrancyGuard {
    function withdraw() public nonReentrant {
        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

**Access Control:**
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";

contract MyContract is AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to) public onlyRole(MINTER_ROLE) {
        // Minting logic
    }
}
```

**Pull Over Push:**
```solidity
// ❌ BAD: Push pattern (vulnerable)
function distribute() public {
    for (uint i = 0; i < recipients.length; i++) {
        recipients[i].transfer(amounts[i]);
    }
}

// ✅ GOOD: Pull pattern (secure)
mapping(address => uint) public pendingWithdrawals;

function withdraw() public {
    uint amount = pendingWithdrawals[msg.sender];
    pendingWithdrawals[msg.sender] = 0;
    payable(msg.sender).transfer(amount);
}
```

### 4. Gas Optimization

```solidity
// Use uint256 instead of smaller uints (saves gas)
uint256 public count; // ✅

// Cache array length
for (uint256 i = 0; i < array.length; i++) // ❌
uint256 length = array.length;
for (uint256 i = 0; i < length; i++) // ✅

// Use unchecked for gas savings (when safe)
unchecked {
    counter++;
}

// Immutable for constants
uint256 public immutable MAX_SUPPLY;
```

### 5. Testing Setup

**Hardhat:**
```javascript
// test/MyToken.test.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MyToken", function () {
  let token;
  let owner;
  let addr1;

  beforeEach(async function () {
    [owner, addr1] = await ethers.getSigners();

    const MyToken = await ethers.getContractFactory("MyToken");
    token = await MyToken.deploy(owner.address);
  });

  it("Should assign total supply to owner", async function () {
    const ownerBalance = await token.balanceOf(owner.address);
    expect(await token.totalSupply()).to.equal(ownerBalance);
  });

  it("Should transfer tokens", async function () {
    await token.transfer(addr1.address, 50);
    expect(await token.balanceOf(addr1.address)).to.equal(50);
  });
});
```

### 6. Deployment Script

```javascript
// scripts/deploy.js
const hre = require("hardhat");

async function main() {
  const [deployer] = await hre.ethers.getSigners();

  console.log("Deploying with account:", deployer.address);

  const MyToken = await hre.ethers.getContractFactory("MyToken");
  const token = await MyToken.deploy(deployer.address);

  await token.waitForDeployment();

  console.log("Token deployed to:", await token.getAddress());

  // Verify on Etherscan
  if (network.name !== "hardhat") {
    await hre.run("verify:verify", {
      address: await token.getAddress(),
      constructorArguments: [deployer.address],
    });
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
```

### 7. Configuration Files

**hardhat.config.js:**
```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    sepolia: {
      url: process.env.SEPOLIA_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
    mainnet: {
      url: process.env.MAINNET_RPC_URL,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
```

### 8. Best Practices

- Use latest Solidity version
- Import from OpenZeppelin
- Add comprehensive tests (>90% coverage)
- Use Slither for static analysis
- Get audited before mainnet
- Use multi-sig for ownership
- Implement pause mechanism
- Follow checks-effects-interactions pattern
- Document all functions with NatSpec
- Version control and CI/CD

### 9. Audit Checklist

- [ ] Reentrancy protection
- [ ] Integer overflow/underflow (use 0.8.0+)
- [ ] Access control properly implemented
- [ ] No unchecked external calls
- [ ] Gas limits considered
- [ ] Front-running mitigation
- [ ] Timestamp dependence avoided
- [ ] Randomness source secure
- [ ] Upgrade mechanism (if proxy)
- [ ] Emergency pause function

### 10. Documentation Template

```solidity
/**
 * @title MyToken
 * @dev Implementation of ERC-20 token with additional features
 * @custom:security-contact security@example.com
 */

/**
 * @notice Mints new tokens
 * @dev Only callable by owner
 * @param to Address to receive tokens
 * @param amount Amount of tokens to mint
 */
function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
}
```

## Installation

```bash
# Initialize project
npm init -y
npm install --save-dev hardhat @openzeppelin/contracts

# Initialize Hardhat
npx hardhat init

# Install dependencies
npm install --save-dev @nomicfoundation/hardhat-toolbox

# Run tests
npx hardhat test

# Deploy
npx hardhat run scripts/deploy.js --network sepolia
```
