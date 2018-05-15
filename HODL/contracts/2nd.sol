pragma solidity ^0.4.22;

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
 * The TokenContract contract does this and that...
 */
contract TokenContract is Ownable{

  using SafeMath for uint;

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

  mapping (uint16 => TokenStandard) public tokensMap;

  uint public newTokenPrice = 1 ether;

  function changeNewTokenPrice (uint _newPrice) external onlyOwner {
    newTokenPrice = _newPrice;
  }
  

  //events
  event OnFirstTokenBought(uint16 indexed _tokenID, address _newOwner);
  event OnChangeSaleToken(uint indexed tokenID, uint indexed price, bool canBuy);
  event TokenBought(address indexed from, address indexed to, uint indexed etherValue, uint tokenID);
  event OnTokenUpdate(uint16 indexed _tokenID, uint8 indexed newLevel, uint8 newStyle);

  // function createNewToken (uint16 _tokenID, uint8 _x, uint8 _y, uint32 _generationDate, address _newOwner, uint8 _tokenLevel, uint8 _tokenStyle) public onlyOwner {
  //   require (tokensMap[_tokenID].tokenLevel == 0);
  //   if(_tokenLevel == 0){
  //     _tokenLevel ++;

  //   }
  //   tokensMap[_tokenID] = TokenStandard(_tokenLevel, _generationDate, _newOwner, 0, uint32(now), Placement(_x,_y), false, false, 0, _tokenStyle);

  //   emit OnFirstTokenBought(_tokenID, _newOwner);
  // }

  uint8 public constant maxCoordinate = 100;
  //100x100 maybe, IDK

  constructor () public {
    owner = msg.sender;
    // emit OnFirstTokenBought(0);

    creationTimestamp = uint32(now);
  }

  function saleToken (uint16 _tokenID, uint _price, bool _canBuy) public {
    require (tokensMap[_tokenID].currentOwner == msg.sender);

    tokensMap[_tokenID].sellingPrice = _price;
    tokensMap[_tokenID].canBuy = _canBuy;
    emit OnChangeSaleToken(_tokenID, _price, _canBuy);
  }

  function buyToken (uint16 _tokenID ) public payable {
    require (tokensMap[_tokenID].canBuy);

    uint etherForTake = 0;

    // if(_newLvl > tokensMap[_tokenID].tokenLevel){
    //     etherForTake = (_newLvl - tokensMap[_tokenID].tokenLevel)* ethForEachLevel;
    //     _setNewLevel(_tokenID, _newLvl, _tokenStyle, etherForTake);
    // }
    
    require (msg.value >= tokensMap[_tokenID].sellingPrice.add(etherForTake));

    tokensMap[_tokenID].lastPurchaseDate = uint32(now);

    tokensMap[_tokenID].currentOwner.transfer(tokensMap[_tokenID].sellingPrice);
    msg.sender.transfer(msg.value.sub(tokensMap[_tokenID].sellingPrice.add(etherForTake)));

    tokensMap[_tokenID].previousOwner = tokensMap[_tokenID].currentOwner;

    tokensMap[_tokenID].canBuy = false;

    emit TokenBought(tokensMap[_tokenID].previousOwner, msg.sender, msg.value, _tokenID);
  }
  
  uint public ethForSecondLevel = 1 ether;
  uint public ethForThirdLevel = 2 ether;
  uint public ethForForthLevel = 3 ether;
  uint public ethForFifthLevel = 4 ether;


  function setNewLevel (uint16 _tokenID, uint8 _newLvl, uint8 _tokenStyle) public payable {
    require (_setNewLevel(_tokenID, _newLvl, _tokenStyle, msg.value));
  }

  function _setNewLevel (uint16 _tokenID, uint8 _newLvl, uint8 _tokenStyle, uint _value) internal returns (bool){
    require (tokensMap[_tokenID].tokenLevel < _newLvl);

    uint etherForTake;

    if (_newLvl == 2){
      etherForTake = ethForSecondLevel;
    }else if (_newLvl == 3){
      etherForTake = ethForThirdLevel;
    }else if (_newLvl == 4){
      etherForTake = ethForForthLevel;
    }else if (_newLvl == 5){
      etherForTake = ethForFifthLevel;
    }

    tokensMap[_tokenID].tokenLevel = _newLvl;
    tokensMap[_tokenID].tokenStyle = _tokenStyle;

    msg.sender.transfer(_value.sub(etherForTake));
    owner.transfer(etherForTake);

    emit OnTokenUpdate( _tokenID, _newLvl, _tokenStyle);

    return true;
  }
  
  uint32 public creationTimestamp;

  Placement[] public availableTokens;

  function pushTokens (uint8[] _x, uint8[] _y) external onlyOwner {
    for (uint i = 0; i < _x.length; i++){
      availableTokens.push(Placement(_x[i], _y[i]));
    }
  }

  function isTokenCreated (uint id) public view returns (bool) {
    if (id < 1000){
      return true;
    }//900 - 15 min
    if ((id-999 * 900) < now - creationTimestamp){
      return true;
    }
  }

  function getTokenGenerationDate (uint id) public view returns (uint32) {
    if (id < 1000){
      return creationTimestamp;
    }
    return uint32(creationTimestamp + (id-999 * 900));
  }

  function buyTokenFromOwner (uint16 _tokenID) external payable {
    require (isTokenCreated(_tokenID) && !createdTokens[_tokenID]);
    
    uint rest = msg.value.sub(newTokenPrice);
    if (rest > 0){
      msg.sender.transfer(rest);
    }
    owner.transfer(newTokenPrice);

    tokensMap[_tokenID] = TokenStandard(1, getTokenGenerationDate(_tokenID), msg.sender, owner, uint32(now), availableTokens[_tokenID], false, false, 0, 0);
    
    createdTokens[_tokenID] = true;

    emit OnFirstTokenBought(_tokenID, msg.sender);
  }

  mapping (uint16 => bool) createdTokens;
  

  function changeSuperBlockId (uint16 index) public onlyOwner {
    require(!tokensMap[index].superBlockID);
    tokensMap[index].superBlockID = true;
  }
  
}
