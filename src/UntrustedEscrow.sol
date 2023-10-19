// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts@5.0.0/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts@5.0.0/token/ERC20/utils/SafeERC20.sol";

/**
 * @title UntrustedEscrow
 * @author Marco Besier
 * @dev This contract represents an untrusted escrow service where a buyer can put an ERC20 token that's arbitrarily
 * specified during deployment into a contract and a seller can withdraw it 3 days later. The seller can also set the
 * price in the constructor and change it later.
 */
contract UntrustedEscrow {
    using SafeERC20 for IERC20;

    struct Deposit {
        uint256 amount;
        uint256 time;
    }

    IERC20 public immutable TOKEN;
    address public immutable SELLER;

    uint256 public constant DEPOSIT_LOCK_PERIOD = 3 days;

    uint256 public price;
    uint256 public depositedTokens;

    mapping(address => Deposit) public deposits;

    event BuyerDeposit(address indexed buyer, uint256 amount, uint256 time);
    event SellerWithdraw(address indexed buyer, uint256 amount, uint256 time);

    modifier onlySeller() {
        require(msg.sender == SELLER, "Only seller can call this function");
        _;
    }

    constructor(address _token, uint256 _price) {
        SELLER = msg.sender;
        TOKEN = IERC20(_token);
        price = _price;
    }

    /**
     * @dev Allows the buyer to deposit the required amount of tokens into the escrow contract.
     * @param _amount The amount of tokens to be deposited by the buyer.
     * Requirements:
     * - The buyer must not have already deposited tokens.
     * - The amount of tokens deposited must be equal to the price of the item.
     * - The buyer must have approved the transfer of tokens to the escrow contract in the TOKEN contract.
     * Emits a {BuyerDeposit} event.
     */
    function buyerDeposit(uint256 _amount) external {
        require(deposits[msg.sender].amount == 0, "Buyer cannot deposit twice");
        require(_amount == price, "Buyer must pay the correct price");
        require(TOKEN.allowance(msg.sender, address(this)) >= _amount, "Buyer must approve transfer in TOKEN contract");

        // Account for potential fee on transfer
        uint256 balanceBefore = TOKEN.balanceOf(address(this));
        TOKEN.safeTransferFrom(msg.sender, address(this), _amount);
        uint256 balanceAfter = TOKEN.balanceOf(address(this));
        uint256 transferredAmount = balanceAfter - balanceBefore;

        depositedTokens += transferredAmount;

        Deposit memory deposit;
        deposit = Deposit({amount: transferredAmount, time: block.timestamp});

        deposits[msg.sender] = deposit;

        emit BuyerDeposit(msg.sender, deposit.amount, deposit.time);
    }

    /**
     * @dev Allows the seller to withdraw the deposited tokens from the contract after the deposit lock period has
     * passed.
     * @param _buyer The address of the buyer who made the deposit.
     * Requirements:
     * - The caller must be the seller.
     * - The buyer must have made a deposit.
     * - The deposit lock period must have passed.
     * Emits a {SellerWithdraw} event.
     */
    function sellerWithdraw(address _buyer) external onlySeller {
        uint256 amount = deposits[_buyer].amount;
        require(amount > 0, "Buyer did not deposit");
        require(block.timestamp - deposits[_buyer].time > DEPOSIT_LOCK_PERIOD, "Deposit lock period not passed");

        delete deposits[_buyer];

        TOKEN.safeTransfer(msg.sender, amount);

        emit SellerWithdraw(_buyer, amount, block.timestamp);
    }

    /**
     * @dev Sets the price of the item being sold by the seller.
     * @param _price The new price of the item.
     * Requirements:
     * - The caller must be the seller.
     */
    function setPrice(uint256 _price) external onlySeller {
        price = _price;
    }
}
