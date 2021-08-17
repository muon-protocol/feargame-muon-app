// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MuonV01.sol";
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

contract MuonFeargame is Ownable {
    using ECDSA for bytes32;

    uint256 public muonAppId = 10;

    MuonV01 public muon;


    // user => (milestone => bool)
    mapping(address => mapping(uint256 => bool)) public claimed;

    // milestoneId => token amount
    mapping(uint256 => uint256) public milestoneAmounts;

    event Claimed(address user, uint256 milestoneId);

    StandardToken public tokenContract =
        StandardToken(0xfc501C2559B426226D37EF5B534c1f2e92BA385A);

    constructor() {
        muon = MuonV01(0xa831c3900102372D0a897DfF0dD9815697aC8064);
        milestoneAmounts[1] = 50 ether;
    }

    function claim(
        address user,
        uint256 milestoneId,
        bytes calldata _reqId,
        bytes[] calldata sigs
    ) public {
        require(sigs.length > 1, "!sigs");

        // We check tx.origin instead of msg.sender to
        // NOT allow other smart contracts to call this function
        require(user == tx.origin, "invalid sender");

        require(!claimed[user][milestoneId], "already claimed");

        bytes32 hash = keccak256(abi.encodePacked(muonAppId, user, milestoneId));
        hash = hash.toEthSignedMessageHash();

        bool verified = muon.verify(_reqId, hash, sigs);
        require(verified, "!verified");
 
        claimed[user][milestoneId] = true;

        tokenContract.transfer(user, milestoneAmounts[milestoneId]);

        emit Claimed(user, milestoneId);
    }

    function setMuonContract(address addr) public onlyOwner {
        muon = MuonV01(addr);
    }

    function setTokenContract(address addr) public onlyOwner {
        tokenContract = StandardToken(addr);
    }

    function setMilestoneAmount(uint256 milestoneId, uint256 amount) public onlyOwner{
        milestoneAmounts[milestoneId] = amount;   
    }

    function ownerWithdrawTokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }
}
