pragma solidity 0.4.24;

// File: contracts/zeppelin/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

  address public owner;

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
  event OwnershipTransferred(address oldOwner, address newOwner);
}

/**
 * @title The HodlMain contract.
 * @dev It contains all token functionality. 
 */
contract HodlMain is Ownable{

  using SafeMath for uint;

  /**
   * @dev Token struct. All Hodl tokens will have the same struct
   * to standartize all tokens.
   */
  struct TokenStandard {
    uint8 tokenLevel; // 0 when generated, 1 when TokenBought
    uint32 generationDate;
    address currentOwner;
    address previousOwner;
    uint32 lastPurchaseDate;
    Placement gridPlacement;
    bool superBlockID;
    bool canBuy;
    uint sellingPrice;
    uint8 tokenStyle;
  }

  struct Placement {
    uint8 x;
    uint8 y; 
  }

  /**
   * @dev this map contains all tokens
   */
  mapping (uint16 => TokenStandard) public tokensMap;

  uint public newTokenPrice = 0.1 ether;

  /**
   * @dev Function to change current token price.
   * @param _newPrice New buying token price
   */
  function changeNewTokenPrice (uint _newPrice) external onlyOwner {
    newTokenPrice = _newPrice;
  }

  //events
  event OnFirstTokenBought(uint16 indexed _tokenID, address _newOwner);
  event OnChangeSaleToken(uint16 indexed tokenID, uint indexed price, bool canBuy);
  event TokenBought(address indexed from, address indexed to, uint indexed etherValue, uint16 tokenID);
  event OnTokenUpdate(uint16 indexed _tokenID, uint8 indexed newLevel, uint8 newStyle);
  event OnChangeSuperBlockId(uint16 tokenID);

  /**
   * @dev Contract constructor.
   */
  constructor () public {
    owner = msg.sender;
    creationTimestamp = uint32(now);
  }

  /**
   * @dev Function to sale token. Can use only by token owner
   * @param _tokenID Token id for sale
   * @param _price New token price (must be in WEI. 1 ETH = 10^18 WEI).
   * @param _canBuy If param = 'false' then token can't be bought. Else token can be bought for 'price' WEI.
   */
  function saleToken (uint16 _tokenID, uint _price, bool _canBuy) public {
    require (tokensMap[_tokenID].currentOwner == msg.sender);

    tokensMap[_tokenID].sellingPrice = _price;
    tokensMap[_tokenID].canBuy = _canBuy;
    emit OnChangeSaleToken(_tokenID, _price, _canBuy);
  }

  /**
   * @dev Function to buy token.
   * If token isn't bought previosly than redirect to '_buyTokenFromOwner'
   * Else redirect to '_buyToken'. In both cases caller must send some ether
   * which equals or more then '_tokenID' price.
   * @param _tokenID Token id for buy.
   */
  function buyToken (uint16 _tokenID ) public payable {
    if (createdTokens[_tokenID]){
      _buyToken(_tokenID, msg.value);
    }else{
      _buyTokenFromOwner(_tokenID, msg.value);
    }
  }

  function _buyToken (uint16 _tokenID, uint _value)  internal {
    require (tokensMap[_tokenID].canBuy);

    require (_value >= tokensMap[_tokenID].sellingPrice);

    tokensMap[_tokenID].lastPurchaseDate = uint32(now);

    tokensMap[_tokenID].currentOwner.transfer(tokensMap[_tokenID].sellingPrice);
    msg.sender.transfer(_value.sub(tokensMap[_tokenID].sellingPrice));

    tokensMap[_tokenID].previousOwner = tokensMap[_tokenID].currentOwner;

    tokensMap[_tokenID].canBuy = false;

    emit TokenBought(tokensMap[_tokenID].previousOwner, msg.sender, tokensMap[_tokenID].sellingPrice, _tokenID);
  }
  
  /**
   * @dev Token update costs block
   */
  uint public ethForFirstLevel = 0.5 ether;
  uint public ethForSecondLevel = 1 ether;
  uint public ethForThirdLevel = 2 ether;
  uint public ethForForthLevel = 3 ether;

  /**
   * @dev Function to change current update token cost.
   * Can be used only contract owner.
   * @param _tokenLevel Token level for change.
   * @param _tokenPrice New token price for '_tokenLevel'. Must be in WEI. (1 ETH = 10^18 WEI).
   */
  function changeUpdateCost (uint _tokenLevel, uint _tokenPrice) public onlyOwner returns (bool) {
    if(_tokenLevel == 1){
      ethForFirstLevel = _tokenPrice;
      return true;
    }
    if(_tokenLevel == 2){
      ethForSecondLevel = _tokenPrice;
      return true;
    }
    if(_tokenLevel == 3){
      ethForThirdLevel = _tokenPrice;
      return true;
    }
    if(_tokenLevel == 4){
      ethForForthLevel = _tokenPrice;
      return true;
    }
    return false;
  }
  // @dev end Token update costs block



  /**
   * @dev Function to update token level and change token style.
   * Can be used only token owner
   * If currect token level = 4 funtion will automatically throw.
   * @param _tokenID Token id for change.
   * @param _newLvl New token level. Token level can be only more then current. Level 4 is maximum.
   * @param _tokenStyle New token style for this token.
   */
  function setNewLevel (uint16 _tokenID, uint8 _newLvl, uint8 _tokenStyle) public payable {
    require (msg.sender == tokensMap[_tokenID].currentOwner);
    require (_setNewLevel(_tokenID, _newLvl, _tokenStyle, msg.value));
  }

  function _setNewLevel (uint16 _tokenID, uint8 _newLvl, uint8 _tokenStyle, uint _value) internal returns (bool){
    require (tokensMap[_tokenID].tokenLevel < _newLvl);

    uint etherForTake;

    if (_newLvl == 1){
      etherForTake = ethForFirstLevel;
    }else if (_newLvl == 2){
      etherForTake = ethForSecondLevel;
    }else if (_newLvl == 3){
      etherForTake = ethForThirdLevel;
    }else if (_newLvl == 4){
      etherForTake = ethForForthLevel;
    }

    tokensMap[_tokenID].tokenLevel = _newLvl;
    tokensMap[_tokenID].tokenStyle = _tokenStyle;

    
    owner.transfer(etherForTake);
    if (_value.sub(etherForTake) > 0)
      msg.sender.transfer(_value.sub(etherForTake));

    emit OnTokenUpdate( _tokenID, _newLvl, _tokenStyle);

    return true;
  }
  
  // @dev contract creation timestamp.
  uint32 public creationTimestamp;

  Placement[] public availableTokens;

  /**
   * @dev Function to initial setup all tokens.
   * This function should be called from project backend
   */
  function pushTokens (uint8[] _x, uint8[] _y) external onlyOwner {
    for (uint i = 0; i < _x.length; i++){
      availableTokens.push(Placement(_x[i], _y[i]));
    }
  }

  /**
   * @dev Function get current token state. Tokens must creating one by one
   * each 15 minutes so if token created this function will return 'true'.
   * @param id Token id to check.
   */
  function isTokenCreated (uint id) public view returns (bool) {
    if (id < 1000){
      return true;
    }//900 - 15 min
    if ((id-999 * 900) < now - creationTimestamp){
      return true;
    }
  }

  /**
   * @dev Function get current token state. Tokens must creating one by one
   * each 15 minutes so if token created this function will return 'true'.
   * @param id Token id to check.
   */
  function getTokenGenerationDate (uint id) public view returns (uint32) {
    if (id < 1000){
      return creationTimestamp;
    }
    return uint32(creationTimestamp + (id-999 * 900));
  }

  function _buyTokenFromOwner (uint16 _tokenID, uint _amount) internal {
    require (isTokenCreated(_tokenID) && !createdTokens[_tokenID]);
    
    uint rest = _amount.sub(newTokenPrice);
    if (rest > 0){
      msg.sender.transfer(rest);
    }
    owner.transfer(newTokenPrice);

    tokensMap[_tokenID] = TokenStandard(0, getTokenGenerationDate(_tokenID), msg.sender, owner, uint32(now), availableTokens[_tokenID], false, false, 0, 0);
    
    createdTokens[_tokenID] = true;

    emit OnFirstTokenBought(_tokenID, msg.sender);
  }

  mapping (uint16 => bool) public createdTokens;
  
  /**
   * @dev Function change super block ID to 'true'
   * Can be used only by contract owner.
   * @param index Token id.
   */
  function changeSuperBlockId (uint16 index) public onlyOwner {
    require(!tokensMap[index].superBlockID);
    tokensMap[index].superBlockID = true;
    emit OnChangeSuperBlockId(index);
  }
}