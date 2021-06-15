// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "Bond.sol";

contract BondSale {
  address _saleTokenContract;
  address _seller;
  uint256 _salePrice;
  bool _sold;

  address _tokenContract;
  uint256 _coupon;
  uint _couponsToIssue;
  uint _interval;

  constructor(address tokenContract_, uint256 coupon_, uint couponsToIssue_, uint interval_, uint256 salePrice_, address saleTokenContract_, address seller_) {
    _saleTokenContract = saleTokenContract_;
    _sold = false;
    _salePrice = salePrice_;
    _seller = seller_;

    _tokenContract = tokenContract_;
    _coupon = coupon_;
    _couponsToIssue = couponsToIssue_;
    _interval = interval_;
  }

  function funded() internal view returns (bool) {
    return IERC20(_tokenContract).balanceOf(address(this)) >= _coupon * _couponsToIssue;
  }

  function coupon() external view returns (uint) {
    return _coupon;
  }

  function couponsToIssue() external view returns (uint) {
    return _couponsToIssue;
  }

  function buy() external returns (address) {
    require(funded(), "Contract must already be funded");
    require(!_sold, "Contract must not already be sold");
    IERC20(_saleTokenContract).transferFrom(msg.sender, address(this), _salePrice);
    Bond bond = new Bond(_tokenContract, msg.sender, _coupon, _couponsToIssue, _interval);
    require(IERC20(_tokenContract).transfer(address(bond), IERC20(_saleTokenContract).balanceOf(address(this))), "Must transfer funds to the bond");
    return address(bond);
  }
  
  function withdraw() external {
    require(msg.sender == _seller, "Only the seller can withdraw the funds");
    require(IERC20(_saleTokenContract).transfer(_seller, IERC20(_saleTokenContract).balanceOf(address(this))), "Must transfer funds back to originator of the contract");
  }
}
