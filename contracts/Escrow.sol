// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC20Mock.sol";

contract Escrow {
    IERC20 public token;
    address public payer;
    address public payee;
    address public arbiter;
    uint256 public amount;
    bool public funded;
    bool public released;

    event Funded(address indexed payer, uint256 amount);
    event Released(address indexed payee, uint256 amount);
    event Refunded(address indexed payer, uint256 amount);

    constructor(address _token, address _payer, address _payee, address _arbiter, uint256 _amount) {
        token = IERC20(_token);
        payer = _payer;
        payee = _payee;
        arbiter = _arbiter;
        amount = _amount;
    }

    function fund() external {
        require(msg.sender == payer, "Only payer");
        require(!funded, "Already funded");
        funded = true;
        bool ok = token.transferFrom(payer, address(this), amount);
        require(ok, "Transfer failed");
        emit Funded(payer, amount);
    }

    function release() external {
        require(msg.sender == arbiter, "Only arbiter");
        require(funded, "Not funded");
        require(!released, "Already released");
        released = true;
        token.transfer(payee, amount);
        emit Released(payee, amount);
    }

    function refund() external {
        require(msg.sender == arbiter, "Only arbiter");
        require(funded, "Not funded");
        require(!released, "Already released");
        released = true;
        token.transfer(payer, amount);
        emit Refunded(payer, amount);
    }
}