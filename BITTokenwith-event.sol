// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract TKNBTTEST is ERC20,AccessControl, Ownable {
    bytes32 public merkleRoot;
    mapping(bytes32 => bool) public txnClaimed;
    bool public paused = false;
    uint256 public maxSupply;

    event Deposit(address sender, uint256 amount);
    event Withdraw(address receiver, uint256 amount);

    
    constructor(uint256 _maxSupply) ERC20("TKNBTTEST", "TKNBT") {
        maxSupply = _maxSupply * (10 ** decimals());
        _mint(msg.sender, 25000000 * (10 ** decimals()));
    }

    function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * (10 ** decimals()));
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function claimTokens(uint256 _amount, bytes32 _signature, bytes32[] calldata _merkleProof) public  {
        require(!paused, "Minting is paused");
        require(_amount > 0, "BIT: Invalid amount");
        require(totalSupply() + _amount * (10 ** decimals()) <= maxSupply, "Max supply exceeded!");
        require(!txnClaimed[_signature],  "BIT: Expired transaction");

        bytes32 leaf = keccak256(abi.encode(_signature, _amount, msg.sender));
        require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "BIT: Unauthorized");
    
        _mint(msg.sender, _amount * (10 ** decimals()));
        txnClaimed[_signature] = true;

        emit Withdraw(msg.sender, _amount);
    }

    function depositTokens(uint256 amount) public  {
        _burn(msg.sender, amount * (10 ** decimals()));
        emit Deposit(msg.sender, amount);
    }

    function transferTokens(address _address, uint256 amount) public  {
        _transfer(msg.sender, _address, amount * (10 ** decimals()));
    }

}