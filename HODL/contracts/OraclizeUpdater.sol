import "./Oraclize.sol";

contract OraclizeUpdater is usingOraclize{
	
	function OraclizeUpdater () public {
		
    	oraclize_setNetwork(networkID_auto);
    	oraclize = OraclizeI(OAR.getAddress());

    // 	oraclizeBalance = msg.value;

    	updateFlag = true;
    	// oraclize_query("URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
    	oraclize_newRandomDSQuery(3600, 999999999, 100000);
	}
	
	uint public lastRandomNumber;

	//Oraclize functions:
  	bool public updateFlag;
 	uint256 public oraclizeBalance;
  	uint public lastUpdateAt;
  
  	event newPriceTicker(string price);

  	function update() internal {
    	oraclize_query(86400,"URL", "json(https://api.kraken.com/0/public/Ticker?pair=ETHUSD).result.XETHZUSD.c.0");
    	//86400 - 1 day
  
    // 	oraclizeBalance = oraclizeBalance.sub(oraclize_getPrice("URL")); //request to oraclize
  	}



  	// function __callback(bytes32, string result, bytes) public {
   //  	require(msg.sender == oraclize_cbAddress());

   //  	uint256 price = 10 ** 23 / parseInt(result, 5);

   //  	require(price > 0);
   //  	// tokenPrice = price*3/100;
    
   //  	// PRE_ICO_MAX_CAP = price.mul((uint)(2000000)); //2 000 000 USD
   //  	// ICO_MIN_CAP = price.mul((uint)(500000)); //500 000 USD


   //  	lastUpdateAt = block.timestamp;
        
   //  	emit newPriceTicker(result);
    
   //  	if(updateFlag){
   //    		update();
   //  	}
  	// }

    event NewRandomNumber_uint(uint);

  	function __callback(bytes32 _queryId, string _result, bytes _proof) public
    { 
        // if we reach this point successfully, it means that the attached authenticity proof has passed!
        require (msg.sender != oraclize_cbAddress());

        if (oraclize_randomDS_proofVerify__returnCode(_queryId, _result, _proof) != 0) {
            // the proof verification has failed, do we need to take any action here? (depends on the use case)
        } else {
            // the proof verification has passed
            // now that we know that the random number was safely generated, let's use it..

            // for simplicity of use, let's also convert the random bytes to uint if we need
            uint maxRange = 2**(8* 7); // this is the highest uint we want to get. It should never be greater than 2^(8*N), where N is the number of random bytes we had asked the datasource to return
            lastRandomNumber = uint(keccak256(_result)) % maxRange; // this is an efficient way to get the uint out in the [0, maxRange] range

            emit NewRandomNumber_uint(lastRandomNumber); // this is the resulting random number (uint)

            update();
        }
    }



  	//End Oraclize functions.
}