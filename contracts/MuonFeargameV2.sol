// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface StandardToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function decimals() external returns (uint8);

    function mint(address reveiver, uint256 amount) external returns (bool);

    function burn(address sender, uint256 amount) external returns (bool);
}

interface IMuonV02 {
    struct SchnorrSign {
        uint256 signature;
        address owner;
        address nonce;
    }
    function verify(
        bytes calldata _reqId,
        uint256 _hash,
        SchnorrSign[] calldata _sigs
    ) external returns (bool);
}

contract MuonFeargameV2 is Ownable {
    using ECDSA for bytes32;

    uint256 public muonAppId = 10;
    uint256 public chainId = 2;

    uint256 public acceptableMuonDelay = 10 minutes;

    IMuonV02 public muon;

    // user => (trackingId => bool)
    mapping(address => mapping(string => bool)) public claimed;

    event Claimed(address user, string trackingId, uint256 reward);

    StandardToken public tokenContract =
        StandardToken(0xa2CA40DBe72028D3Ac78B5250a8CB8c404e7Fb8C);

    uint256 public maxPerTX = 500 ether;
    uint256 public maxPerUser = 5000 ether;

    mapping(address => uint256) public totalClaimed;

    constructor() {
        muon = IMuonV02(0xE0686e70d80837360bfCdFE4dE9D78715459B552);
    }

    function claim(
        address user,
        uint256 reward,
        string calldata trackingId,
        uint256 chain,
        uint256 muonTimestamp,
        bytes calldata _reqId,
        IMuonV02.SchnorrSign[] calldata _sigs
    ) public {
        require(block.timestamp - muonTimestamp < acceptableMuonDelay, "expired");
        require(_sigs.length > 0, "!sigs");
        require(reward > 0, "0 reward");

        require(chain == chainId, "invalid chain");

        totalClaimed[user] += reward;
        require(reward <= maxPerTX &&  totalClaimed[user] <= maxPerUser, "> max");

        // We check tx.origin instead of msg.sender to
        // NOT allow other smart contracts to call this function

        require(user == tx.origin, "invalid sender");

        require(!claimed[user][trackingId], "already claimed");

        bytes32 hash = keccak256(
            abi.encodePacked(muonAppId, user, reward, trackingId, chain, muonTimestamp)
        );
        require(muon.verify(_reqId, uint256(hash), _sigs), "!verified");

        claimed[user][trackingId] = true;

        tokenContract.transfer(user, reward);

        emit Claimed(user, trackingId, reward);
    }

    function setMuonContract(address addr) public onlyOwner {
        muon = IMuonV02(addr);
    }

    function setTokenContract(address addr) public onlyOwner {
        tokenContract = StandardToken(addr);
    }

    function setMaxPerTX(uint256 _val) public onlyOwner {
        maxPerTX = _val;
    }

    function setMaxPerUser(uint256 _val) public onlyOwner {
        maxPerUser = _val;
    }

    function setAcceptableMuonDelay(uint256 _val) public onlyOwner {
        acceptableMuonDelay = _val;
    }

    function setChainId(uint256 _val) public onlyOwner {
        chainId = _val;
    }

    function ownerWithdrawTokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }

    function ownerWithdrawETH(address _to, uint256 _amount) public onlyOwner {
        payable(_to).transfer(_amount);
    }
}
