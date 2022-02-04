//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../BEP721/BEP721.sol";
import "../security/Context.sol";

/**
 * @dev Marketplace is a base contract that contains basic 
 * functionality for all inheriting marketplace contracts.
 * Note: Currently only supports a fixed price type of sale.
 */
abstract contract MarketplaceCore is Context {
    /// @dev Represents a fixed price sale of the NFT
    struct FixedPriceSale {
        // seller of the NFT
        address seller;
        // price of the NFT being sold in wei
        uint128 price;
        // timestamp of when sale of NFT starts, 0 when concluded
        uint256 startedAt;
    }

    /// @dev sales fee for all NFT sales, ranges from 0 - 10000 to accommodate double decimal points
    uint16 public salesFee;

    /// @dev developer's cut for all NFT sales, ranges from 0 - 10000 to accommodate double decimal places.
    uint16 public devCut;

    /**
     * @dev Two mappings to store NFT sales in the marketplace.
     * salesByAddress maps from the seller to an NFT ID they're selling and returns an instance of the 
     * FixedPriceSale struct for this particular NFT.
     * 
     * sales maps directly from the NFT ID (no need for the address) and returns the FixedSalePrice
     * struct for this particular NFT.
     */
    mapping (uint256 => FixedPriceSale) public sales;

    /// @dev Triggers whenever a user sells their NFT.
    event SaleCreated(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        uint128 _price,
        uint256 _startedAt,
        address _seller
    );

    /// @dev Triggers whenever an NFT is successfully sold.
    event Sold(
        address indexed _nftContract,
        uint256 indexed _tokenId,
        uint256 _price,
        address _soldBy,
        address _newOwner
    );

    /**
     * @dev Triggers when an ongoing sale of the NFT is cancelled.
     */
    event CancelSale(
        address indexed _nftContract,
        uint256 indexed _tokenId
    );

    /**
     * @dev Checks if the _seller owns _tokenId. Returns true if they do.
     */
    function _owns(address _nftContract, address _seller, uint256 _tokenId) internal view returns (bool) {
        BEP721 nftContract_ = _getNftContract(_nftContract);
        return (nftContract_.ownerOf(_tokenId) == _seller);
    }

    /**
     * @dev Transfers the NFT from _owner to this contract (address(this)) and therefore
     * also assigns/transfers the ownership from _owner to this contract as well.
     * Throws if escrow fails.
     *
     * @dev Note: Please assure that the user already approves the contract for transferring
     * via calling the approve() function in {BEP721}.
     */
    function _escrow(address _nftContract, address _owner, uint256 _tokenId) internal {
        BEP721 nftContract_ = _getNftContract(_nftContract);
        nftContract_.safeTransferFrom(_owner, address(this), _tokenId);
    }

    /**
     * @dev Transfers an NFT owned by this contract to _to.
     */
    function _transfer(address _nftContract, address _to, uint256 _tokenId) internal {
        BEP721 nftContract_ = _getNftContract(_nftContract);
        nftContract_.safeTransfer(address(this), _to, _tokenId,"");
    }

    /**
     * @dev Adds the fixed price (FP) sale to the map/list of current sales.
     * Emits the SaleCreated event.
     */
    function _addFPSale(address _nftContract, uint256 _tokenId, FixedPriceSale memory _fpSale, address _seller) internal {
        sales[_tokenId] = _fpSale;
        emit SaleCreated(
            _nftContract,
            _tokenId,
            _fpSale.price,
            _fpSale.startedAt,
            _seller
        );
    }

    /**
     * @dev Cancels the FP sale and removes it from the map/list of current sales.
     * Emits the CancelSale event.
     */
    function _cancelFPSale(address _nftContract, uint256 _tokenId, address _seller) internal {
        _removeSale(_tokenId);
        _transfer(_nftContract, _seller, _tokenId);
        emit CancelSale(_nftContract, _tokenId);
    }

    /**
     *@dev Computes total fees for all sales based on the price.
     */
    function _computeTotalFee(uint128 _price) internal view returns (uint128) {
        return _price * (devCut + salesFee) / 100;
    }

    /**
     * @dev Buyer purchases the NFT and transfers payment to seller.
     */
    function _buy(address _nftContract, uint256 _tokenId, uint128 _buyAmount) internal {
        FixedPriceSale storage _fpSale = sales[_tokenId];
        require(_isOnSale(_fpSale), "FixedPrice: Specified NFT is not on sale");

        uint128 _price = _fpSale.price;
        require(_buyAmount >= _price);
        address payable _seller = payable(_fpSale.seller);
        _removeSale(_tokenId);

        if (_price > 0) {
            uint128 _sellerProceeds = _price - _computeTotalFee(_price);
            _seller.transfer(_sellerProceeds);
        }

        emit Sold(_nftContract, _tokenId, _price, _seller, _msgSender());
    }

    /**
     * @dev Removes the sale from the list of open sales.
     */
    function _removeSale(uint256 _tokenId) internal {
        delete sales[_tokenId];
    }

    /**
     * @dev Checks if the NFT is on sale.
     */
    function _isOnSale(FixedPriceSale memory _fpSale) internal pure returns (bool) {
        return (_fpSale.startedAt > 0);
    }

    /**
     * @dev Returns the BEP721 type of the looked up _nftContract.
     */
    function _getNftContract(address _nftContract) internal pure returns (BEP721) {
        return BEP721(_nftContract);
    }







}