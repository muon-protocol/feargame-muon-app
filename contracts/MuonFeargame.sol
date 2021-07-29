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

    MuonV01 public muon;

    // user => (milestone => bool)
    mapping(address => mapping(uint256 => bool)) public claimed;


    // milestoneId => token amount
    mapping(uint256 => uint256) public milestoneAmounts;

    event Claimed(
        address user,
        uint256 milestoneId
    );

    StandardToken public tokenContract = StandardToken(
        address(0) //TODO: token contract here
    );

    constructor() {
        muon = MuonV01(
            address(0) // TODO: muon address here
        );
        milestoneAmounts[1] = 10 ether;
    }

    function claim(
        address user,
        uint256 milestoneId,
        bytes calldata _reqId,
        bytes[] calldata sigs
    ) public{
        require(sigs.length > 1, "!sigs");
        require(user == msg.sender, "invalid sender");
        require(!claimed[user][milestoneId], "already claimed");

        bytes32 hash = keccak256(
            abi.encodePacked(
                user,
                milestoneId
            )
        );
        hash = hash.toEthSignedMessageHash();

        bool verified = muon.verify(_reqId, hash, sigs);
        require(verified, "!verified");

        tokenContract.transfer(
            user, milestoneAmounts[milestoneId]
        );
        
        emit Claimed(
            user,
            milestoneId
        );
    }

    function setMuonContract(address addr) public onlyOwner {
        muon = MuonV01(addr);
    }

    function ownerWithdrawTokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        StandardToken(_tokenAddr).transfer(_to, _amount);
    }
}
