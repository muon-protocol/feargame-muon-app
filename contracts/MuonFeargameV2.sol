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

struct SchnorrSign {
    uint256 signature;
    address owner;
    address nonce;
}


interface IMuonV02{
    function verify(bytes calldata _reqId, uint256 _hash, SchnorrSign[] calldata _sigs) external returns (bool);
}

contract MuonFeargame is Ownable {
    using ECDSA for bytes32;

    uint256 public muonAppId = 10;

    IMuonV02 public muon;


    // user => (trackingId => bool)
    mapping(address => mapping(bytes => bool)) public claimed;

    event Claimed(address user, bytes trackingId, uint256 reward);

    StandardToken public tokenContract =
        StandardToken(0xa2CA40DBe72028D3Ac78B5250a8CB8c404e7Fb8C);

    constructor() {
        muon = IMuonV02(0xFc8DcBB38dFef91ADfD776e4FaCd6f6892De9a35);
    }

    function claim(
        address user,
        uint256 reward,
        bytes calldata trackingId,
        bytes calldata _reqId,
        SchnorrSign[] calldata _sigs
    ) public {
        require(_sigs.length > 1, "!sigs");
        require(reward > 0, "0 reward");

        // We check tx.origin instead of msg.sender to
        // NOT allow other smart contracts to call this function
        
        //TODO: uncomment this. commented just for testing
        
        //require(user == tx.origin, "invalid sender");

        require(!claimed[user][trackingId], "already claimed");

        // bytes32 hash = keccak256(abi.encodePacked(muonAppId, user, milestoneId));
        // hash = hash.toEthSignedMessageHash();

        // bool verified = muon.verify(_reqId, hash, sigs);
        // require(verified, "!verified");

        bytes32 hash = keccak256(abi.encodePacked(muonAppId,
            user, reward, trackingId
        ));
        require(muon.verify(_reqId, uint256(hash), _sigs), '!verified');

 
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


    function ownerWithdrawTokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }

    function ownerWithdrawETH(
        address _to,
        uint256 _amount
    ) public onlyOwner {
        payable(_to).transfer(_amount);
    }
}
