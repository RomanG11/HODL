pragma solidity ^0.4.19;

library SafeMath { //standart library for uint
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0 || b == 0){
        return 0;
    }
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable { //standart contract to identify owner

  address public owner;

  address public newOwner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function Ownable() public {
    owner = msg.sender;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      owner = newOwner;
    }
  }
}

/**
 * The TokenContract contract does this and that...
 */
contract TokenContract is Ownable{

  using SafeMath for uint;

  struct TokenStandard {
    // uint blockID; //autoincrement
    uint8 blockLevel; // 0 when generated, 1 when TokenBought
    uint generationDate;
    address currentOwner;
    address previousOwner;
    uint lastPurchaseDate;
    Placement gridPlacement;
    bool superBlockID;
    bool canBuy;
    uint sellingPrice;
    uint blockStyle;
  }

  struct Placement {
    uint8 x;
    uint8 y; 
  }

  mapping (uint16 => TokenStandard) tokens;
  



  uint8 public constant maxCoordinate = 100;
  //100x100 maybe, IDK

  TokenStandard[] public tokens;  
 
  bool[maxCoordinate][maxCoordinate] public availablePlaces;

  bool[maxCoordinate][maxCoordinate] public holdPlases;
  
  function _changeAvailablePlaces (uint _x, uint _y) internal {
    if(_x != 0){
      if(!holdPlases[_x-1][_y]){
        if(!availablePlaces[_x-1][_y]){
          availablePlaces[_x-1][_y] = true;
          newPlacements.push(Placement(uint8(_x-1),uint8(_y)));
        }
      }
    }
    if(_x != maxCoordinate){
      if(!holdPlases[_x+1][_y]){
        if(!availablePlaces[_x+1][_y]){
          availablePlaces[_x+1][_y] = true;
          newPlacements.push(Placement(uint8(_x+1),uint8(_y)));
        }
      }
    }
    if(_y != 0){
      if(!holdPlases[_x][_y-1]){
        if(!availablePlaces[_x][_y-1]){
          availablePlaces[_x][_y-1] = true;
          newPlacements.push(Placement(uint8(_x),uint8(_y-1)));
        }
      }
    }
    if(_y != maxCoordinate){
      if(!holdPlases[_x][_y+1]){
        if(!availablePlaces[_x][_y+1]){
          availablePlaces[_x][_y+1] = true;
          newPlacements.push(Placement(uint8(_x),uint8(_y+1)));
        }
      }
    }

    availablePlaces[_x][_y] = false;
    holdPlases[_x][_y] = true;

    // for (uint i = 0; i < newPlacements.length; i++){
    //   if(newPlacements[i].x == _x && newPlacements[i].y = _y){
    //     holdPlacements.push(i);
    //   }
    // }
  }

  function checkIsNewTokenCanBeThere (uint _x, uint _y) public view returns (bool) {
    if(availablePlaces[_x][_y] && !holdPlases[_x][_y]){
      return true;
    }
    return false;
  }
  
  
  Placement[] public newPlacements;  
  Placement public place;


  function getPlaceForNewToken (uint _random) internal returns(Placement) {
    require (_random < newPlacements.length);

    Placement memory buffer;

    if(newPlacements[_random].x != 0 && newPlacements[_random].y != 0){
      if (checkIsNewTokenCanBeThere(newPlacements[_random].x, newPlacements[_random].y)){
        _changeAvailablePlaces(newPlacements[_random].x, newPlacements[_random].y);
        buffer = newPlacements[_random];
        delete newPlacements[_random];
        return buffer;
      }
    }else{
      for (uint i = 0; i < newPlacements.length; i++){
        if(checkIsNewTokenCanBeThere(newPlacements[i].x, newPlacements[i].y)){
          _changeAvailablePlaces(newPlacements[i].x, newPlacements[i].y);
          buffer = newPlacements[i];
          delete newPlacements[i];
          return buffer;
        }
      }
    }
  }
  
  function createNewToken (uint8 x, uint8 y) public {
    TokenStandard memory buffer;
    buffer.blockLevel = 1;
    buffer.generationDate = now;
    buffer.currentOwner = owner;
    // buffer.blockStyle = 0;
    
    place = Placement(x,y);
    
    // Placement storage plase = 

    buffer.gridPlacement = place;
    buffer.superBlockID = true;

    // _changeAvailablePlaces(place.x,place.y);

    tokens.push(buffer);

    // emit OnTokenCreated(1, place.x, place.y, true);
    emit TokenCreate(tokens.length, now, owner, place.x, place.y, true,0,0, 1 ether);
  }

//   event OnTokenCreated(uint8 indexed _blockLevel, uint indexed _x, uint indexed _y, bool _superBlockID);
  event OnChangeSaleToken(uint indexed tokenID, uint indexed price, bool canBuy);
  event TokenBought(address indexed from, address indexed to, uint indexed etherValue, uint tokenID);
  
  function manuallyCreateNewToken (uint8 _blockLevel, uint _x, uint _y, bool _superBlockID) public {

    
    TokenStandard memory buffer;
    buffer.blockLevel = _blockLevel;
    buffer.generationDate = now;
    buffer.currentOwner = owner;
    buffer.gridPlacement = Placement(uint8(_x),uint8(_y));
    buffer.superBlockID = _superBlockID;

    holdPlases[_x][_y] = true;
    _changeAvailablePlaces(_x,_y);

    tokens.push(buffer);
    
    emit TokenCreate(tokens.length, now, owner, _x, _y, _superBlockID,0,0, 1 ether);
    // emit OnTokenCreated(tokens.length, _x, _y, _superBlockID);
  }
  
  function saleToken (uint _tokenID, uint _price, bool _canBuy) public {
    require (tokens[_tokenID].currentOwner == msg.sender);

    tokens[_tokenID].sellingPrice = _price;
    tokens[_tokenID].canBuy = _canBuy;
    emit OnChangeSaleToken(_tokenID, _price, _canBuy);
  }

  function buyToken (uint _tokenID) public payable {
    require (tokens[_tokenID].canBuy);
    require (msg.value >= tokens[_tokenID].sellingPrice);
    

    tokens[_tokenID].lastPurchaseDate = now;

    tokens[_tokenID].currentOwner.transfer(msg.value);
    tokens[_tokenID].previousOwner = tokens[_tokenID].currentOwner;

    tokens[_tokenID].canBuy = false;

    emit TokenBought(tokens[_tokenID].previousOwner, msg.sender, msg.value, _tokenID);
  }
  
   function buyTokenFromOwner (uint _tokenID, address _newTokenOwner, uint _ether) public onlyOwner {
    require (tokens[_tokenID].canBuy);
    require (_ether >= tokens[_tokenID].sellingPrice);
    

    tokens[_tokenID].lastPurchaseDate = now;

    tokens[_tokenID].previousOwner = tokens[_tokenID].currentOwner;

    tokens[_tokenID].canBuy = false;

    emit TokenBought(tokens[_tokenID].previousOwner, _newTokenOwner, 0, _tokenID);
  }
  

  function giftToken (address _address, uint _tokenID) public {
    require (tokens[_tokenID].currentOwner == msg.sender);

    tokens[_tokenID].previousOwner = tokens[_tokenID].currentOwner;
    tokens[_tokenID].currentOwner = _address;

    emit TokenBought(tokens[_tokenID].previousOwner, msg.sender, 0, _tokenID);
  }
  
  // event OnTokenCreated(uint8 indexed _blockLevel, uint indexed _x, uint indexed _y, bool _superBlockID);
  // event OnChangeSaleToken(uint indexed tokenID, uint indexed price, bool canBuy);
  // event TokenBought(address indexed from, address indexed to, uint indexed etherValue, uint tokenID);
  
//   event TokenCreate(uint tokenID, uint generationDate, address currentOwner, uint x, uint y, bool superBlockID, uint blockStyle);
  event TokenCreate(uint blockID, uint generationDate, address currentOwner, uint x, uint y, bool superBlockID,uint blockStyle, uint blockType, uint tokenPrice);

  function TokenContract () public {
    owner = msg.sender;
    createFirstToken();
    setGenerationPlaces();
    // emit OnTokenCreated(1, 50, 50, true);
    // emit TokenCreate(2, now, owner, 50, 49, true,8);
    // emit OnChangeSaleToken(2, 2343564, true);
    // emit TokenBought(0xca35b7d915458ef540ade6068dfe2f44e8fa733c, 0xca35b7d915458ef540ade6068dfe2f44e8fa7332, 9999999, 1);
  }
  
//   struct TokenStandard {
//     // uint blockID; //autoincrement
//     uint8 blockLevel; // =1 when generated
//     uint generationDate;
//     address currentOwner;
//     address previousOwner;
//     uint lastPurchaseDate;
//     Placement gridPlacement;
//     bool superBlockID;
//     bool canBuy;
//     uint sellingPrice;
//     uint blockStyle;
//   }

  function createFirstToken() internal{
    TokenStandard memory buffer;
    buffer.blockLevel = 1;
    buffer.generationDate = now;
    buffer.currentOwner = owner;
    
    place = Placement(maxCoordinate/2, maxCoordinate/2);
    
    // Placement storage plase = 

    buffer.gridPlacement = place;
    buffer.superBlockID = true;

    _changeAvailablePlaces(place.x,place.y);

    tokens.push(buffer);

    // emit OnTokenCreated(1, place.x, place.y, true);
    emit TokenCreate(0, now, owner, place.x, place.y, true,0,0, 1 ether);
    // emit OnChangeSaleToken(1, 200, true);
    // emit OnChangeSuperBlockId(1, true);
    //   emit OnTokenUpdate(3, 2);

//   emit TokenBought(0x1, 0x2, 200, 2);
  }

  event OnChangeSuperBlockId(uint tokenId, bool superBlockID);
  

  function changeSuperBlockId (uint _id, bool _bool) public onlyOwner {
    tokens[_id].superBlockID = _bool;
    emit OnChangeSuperBlockId(_id, _bool);
  }

  address public distributionAddress;

  event OnTokenUpdate(uint tokenId, uint8 tokenLevel);
  

  function updateTokenLevel (uint _id) public payable {
    require (tokens[_id].blockLevel < 5);
    require (msg.value > 0.1 ether);

    distributionAddress.transfer(0.1 ether);

    tokens[_id].blockLevel = tokens[_id].blockLevel+1;

    msg.sender.transfer(address(this).balance);
    
    emit OnTokenUpdate(_id, tokens[_id].blockLevel);
    
  }
  
  
  Placement[] public geterationPlaces;

  function setGenerationPlaces () internal {


    // geterationPlaces.push(Placement(1,18));
    // for (uint8 i = 20; i <= 96; i++){
    //   geterationPlaces.push(Placement(i,1));
    // }

    // for (i = 1; i >= 5; i++){
    //   geterationPlaces.push(Placement(18,i));
    // }

    // for (i = 20; i <= 26 i++){
    //   geterationPlaces.push(Placement(i,3));
    // }
    // for (i = 28; i <= 44 i++){
    //   geterationPlaces.push(Placement(i,3));
    // }
    // for (i = 46; i <= 70 i++){
    //   geterationPlaces.push(Placement(i,3));
    // }
    // for (i = 72; i <= 95 i++){
    //   geterationPlaces.push(Placement(i,3));
    //   geterationPlaces.push(Placement(i,5));
    //   geterationPlaces.push(Placement(i,9));
    // }
    
    // for (i = 2; i <= 38; i++){
    //   geterationPlaces.push(Placement(97,i));
    // }

    // for(i = 4; i <= 24; i++){
    //   geterationPlaces.push(Placement(i,4);
    // }

    // for(i = 4; i <= 11; i++){
    //   geterationPlaces.push(Placement(26,i));
    //   geterationPlaces.push(Placement(28,i));
    // }

    // geterationPlaces.push(Placement(5,25));

    // for(i = 30; i <= 44; i++){
    //   geterationPlaces.push(Placement(i,5));
    // }

  }
  

  
}
