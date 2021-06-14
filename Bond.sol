// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

contract Bond {
  address _tokenContract;
  address _recipient;
  uint256 _coupon;
  uint _startDate;
  uint _couponsIssued;
  uint _couponsToIssue;
  uint _interval;

  constructor(address tokenContract_, address recipient_, uint256 coupon_, uint couponsToIssue_, uint interval_) {
    _tokenContract = tokenContract_;
    _coupon = coupon_;
    _startDate = block.timestamp;
    _couponsIssued = 0;
    _couponsToIssue = couponsToIssue_;
    _interval = interval_;
    _recipient = recipient_;
  }

  function coupon() external view returns (uint) {
    return _coupon;
  }

  function recipient() external view returns (address) {
    return _recipient;
  }

  function startDate() external view returns (uint) {
    return _startDate;
  }

  function couponsIssued() external view returns (uint) {
    return _couponsIssued;
  }

  function couponsToIssue() external view returns (uint) {
    return _couponsToIssue;
  }
  
  function withdraw() external returns (uint256) {
    uint _couponsPotentiallyEarned = (block.timestamp - _startDate) / _interval;
    uint _couponsEarned = _couponsPotentiallyEarned > _couponsToIssue ? _couponsToIssue : _couponsPotentiallyEarned;
    uint _couponsOwed = _couponsEarned - _couponsIssued;
    if (IERC20(_tokenContract).transfer(_recipient, _coupon * _couponsOwed)) {
      // happy path, transferred the owed balance to the recipient
      _couponsIssued = _couponsEarned;
      return _coupon * _couponsOwed;
    } else {
      // sad path, don't have the funds to do so... transfer the number of coupons
      // we do have enough funds for
      uint256 _availableCoupons = IERC20(_tokenContract).balanceOf(address(this)) / _coupon;
      // make sure that we actually can transfer the tokens the token contract claims we own,
      // and that we actually don't have enough for the happy path. either of these cases indicate
      // an unhappy ERC20 token
      require(
        _availableCoupons < _couponsOwed
      , "I could not transfer these coupons even though I possess them. This probably indicates a buggy ERC20 contract."
      );
      require(
        IERC20(_tokenContract).transfer(_recipient, _availableCoupons * _coupon)
      , "Could not even transfer the tokens that the contract owns. This probably indicates a buggy ERC20 contract."
      );
      _couponsIssued = _couponsIssued + _availableCoupons;
      return _coupon * _availableCoupons;
    }
  }

  function withdrawalLimit() external view returns (uint256) {
    uint _couponsPotentiallyEarned = (block.timestamp - _startDate) / _interval;
    uint _couponsEarned = _couponsPotentiallyEarned > _couponsToIssue ? _couponsToIssue : _couponsPotentiallyEarned;
    uint _couponsOwed = _couponsEarned - _couponsIssued;
    return _coupon * _couponsOwed;
  }
}
