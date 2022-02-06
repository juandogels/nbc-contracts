//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../marketplace/MarketplaceCore.sol";
import "../security/Pausable.sol";

/**
 * @dev Contract for marketplace logic
 */
contract NBMarketplace is MarketplaceCore, Pausable {

    /**
     * @dev Sets both developer's cut and sales fee when contract is deployed.
     */
    constructor(uint16 _devCut, uint16 _salesFee) {
        require(_devCut <= 10000, "NBMarketplace: Specified dev cut is over limits");
        require(_salesFee <= 10000, "NBMarketpalce: Specified sales fee is over limits");

        devCut = _devCut;
        salesFee = _salesFee;
    } 

    /**
     * @dev Creates a new sale and adds it to the list of open sales.
     */
    function createSale(
        address _nftContract,
        uint256 _tokenId, 
        uint128 _price
    ) public whenNotPaused {
        address _seller = _msgSender();
        require(_owns(_nftContract, _seller, _tokenId), "NBMarketplace: Seller does not own specified NFT");
        _escrow(_nftContract, _seller, _tokenId);
        
        FixedPriceSale memory _fpSale = FixedPriceSale(
            _seller,
            _price,
            block.timestamp
        );

        _addFPSale(_nftContract, _tokenId, _fpSale, _seller);
    }

    /**
     * @dev Buys an open sale and completes it. Transfers ownership of the NFT to _msgSender()/buyer 
     * if enough funds are supplied.
     */
    function buy(address _nftContract, uint256 _tokenId) public payable whenNotPaused {
        _buy(_nftContract, _tokenId, uint128(msg.value));
        _transfer(_nftContract, _msgSender(), _tokenId);
    }

    /**
     * @dev Cancels an open sale that hasn't been bought by anyone yet. Returns the NFT to the seller/original owner.
     * Note: Can be called when contract is paused.
     */
    function cancelSale(address _nftContract, uint256 _tokenId) public {
        FixedPriceSale storage _fpSale = sales[_nftContract][_tokenId];
        require(_isOnSale(_fpSale), "NBMarketplace: Specified NFT is not on sale");
        require(_msgSender() == _fpSale.seller, "NBMarketplace: _msgSender() is not the seller of the NFT");
        _cancelFPSale(_nftContract, _tokenId, _fpSale.seller);
    }

    /**
     * @dev Cancels an open sale that hasn't been bought yet when the contract is paused.
     * Only the owner of the contract can do this and should only be used in emergencies.
     */
    function cancelSaleWhenPaused(address _nftContract, uint256 _tokenId) public whenPaused onlyAdmin {
        FixedPriceSale storage _fpSale = sales[_nftContract][_tokenId];
        require(_isOnSale(_fpSale), "NBMarketplace: Specified NFT is not on sale");
        _cancelFPSale(_nftContract, _tokenId, _fpSale.seller);
    }

    /**
     * @dev Returns sale info for an NFT on sale.
     */
    function getFPSale(address _nftContract, uint256 _tokenId) public view returns (address _seller, uint128 _price, uint256 _startedAt) {
        FixedPriceSale storage _fpSale = sales[_nftContract][_tokenId];
        require(_isOnSale(_fpSale), "NBMarketplace: Specified NFT is not on sale");

        return (_fpSale.seller, _fpSale.price, _fpSale.startedAt);
    }

}