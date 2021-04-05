package main

import (
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"strconv"
	"time"

	"github.com/hyperledger/fabric-chaincode-go/shim"
	"github.com/hyperledger/fabric-contract-api-go/contractapi"
)

// SmartContract provides functions for managing an Asset
type SmartContract struct {
	contractapi.Contract
}

func main() {
	assetChaincode, err := contractapi.NewChaincode(&SmartContract{})
	if err != nil {
		log.Panicf("Error creating random-test chaincode: %v", err)
	}

	if err := assetChaincode.Start(); err != nil {
		log.Panicf("Error starting random-test chaincode: %v", err)
	}
}

// RandomBox describes random box details of game item
type RandomBox struct {
	DocType        string  `json:"DocType"`
	ID             string  `json:"ID"`             // Hashed Value. Not for user's
	GameName       string  `json:"GameName"`       // Game Name  ex. MapleStory
	ServerName     string  `json:"ServerName"`     // Server Name ex. Scania
	CharacterName  string  `json:"CharacterName"`  // Character Name which means the user's chosen name in game. ex. "N0tail", "Faker" without Double quotes
	RandomBoxName  string  `json:"RandomBoxName"`  // Random Box Name which user used. ex. "Treasure of the Forgotten Myth" without Double quotes
	OpenedUnixTime string  `json:"OpenedUnixTime"` // Unix Nano Time when block chain code requested to make some random number. If Game server request several random number in a same time, nano time would be different because of "Ordering Service" of Hyperledger Chaincode.
	Maximum        int64   `json:"Maximum"`        // Maximum Number of this Random number
	Results        []int64 `json:"Results"`        // Generated Random number by chaincode
}

/* Impossible to make "Cryptographically secure pseudorandom number" because this is not deterministic
// GenerateRandomInt64 generate "Cryptographically secure pseudorandom number (aka. CSPRNG)"
func GenerateRandomInt64() (int64, error) {
	val, err := rand.Int(rand.Reader, big.NewInt(int64(math.MaxInt64)))
	if err != nil {
		return 0, err
	}
	return val.Int64(), nil
}

// GenerateRandomInt64WithLimit generate "Cryptographically secure pseudorandom number (aka. CSPRNG)" from (including) 0 to (excluding) maximum [0,maximum).
func GenerateRandomInt64WithLimit(maximum int64) (int64, error) {
	val, err := rand.Int(rand.Reader, big.NewInt(maximum))
	if err != nil {
		return 0, err
	}
	return val.Int64(), nil
}
*/

/*GenerateRandomInt64WithLimit generate Pseudorandom number from (including) 0 to (excluding) maximum [0,maximum).
This Function is not "Cryptographically secure pseudorandom number (aka. CSPRNG)" because peer's generated random number would be different. (It means that all database would not be same.)
So, My solution is using transaction timestamp as seed
*/
func GenerateRandomInt64WithLimit(seed int64, maximum int64) int64 {
	rand.Seed(seed)
	return rand.Int63n(maximum)
}

// GenerateManyRandomInt64WithLimit generate random numbers as array.
func GenerateManyRandomInt64WithLimit(seed int64, maximum int64, howmany uint16) []int64 {
	rand.Seed(seed)
	var ret []int64 = make([]int64, howmany)
	for i := range ret {
		ret[i] = rand.Int63n(maximum)
	}
	return ret
}

// OpenRandomBox issues a new random box information with generated random number
func (s *SmartContract) OpenRandomBox(ctx contractapi.TransactionContextInterface, gameName string, serverName string, characterName string, randomBoxName string, maximum int64) error {
	// Error Check
	if maximum > 1000000000000000000 || maximum < 1 {
		return fmt.Errorf("Maximum value is out of bound. (0 < maximum < 1,000,000,000,000,000,000). And your maximum input was [%d]", maximum)
	}

	// Making ID
	// nowUnixNanoTime := strconv.\FormatInt(time.Now().UnixNano(), 10)		// This is Failure. Because of https://stackoverflow.com/questions/55289283/hyperledger-fabric-error-could-not-assemble-transaction-proposalresponsepaylo

	transactionTimestamp, errN := ctx.GetStub().GetTxTimestamp()
	if errN != nil {
		return fmt.Errorf("Failed to get TransactionTimeStamp")
	}
	now := time.Unix(transactionTimestamp.Seconds, int64(transactionTimestamp.Nanos))
	nowString := now.String()
	nowUnixNanoTime := now.UnixNano()

	message := gameName + serverName + characterName + randomBoxName + nowString + strconv.FormatInt(maximum, 10) // Before Hash function
	hash := sha256.New()
	hash.Write([]byte(message))
	digest := hash.Sum(nil)
	id := hex.EncodeToString(digest)

	exists, err := ctx.GetStub().GetState(id)
	if err != nil {
		return err
	}
	if exists != nil {
		return fmt.Errorf("Already exists! %s", message)
	}

	results := GenerateRandomInt64WithLimit(nowUnixNanoTime, maximum)

	randomBox := RandomBox{
		DocType:        "RandomBox",
		ID:             id,
		GameName:       gameName,
		ServerName:     serverName,
		CharacterName:  characterName,
		RandomBoxName:  randomBoxName,
		OpenedUnixTime: nowString,
		Maximum:        maximum,
		Results:        []int64{results},
	}

	randomBoxJSON, err := json.Marshal(randomBox)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, randomBoxJSON)
}

// OpenRandomBoxes issues a new random boxes information with generated random numbers
func (s *SmartContract) OpenRandomBoxes(ctx contractapi.TransactionContextInterface, gameName string, serverName string, characterName string, randomBoxName string, maximum int64, howmany uint16) error {
	// Error Check
	if maximum > 1000000000000000000 || maximum < 1 {
		return fmt.Errorf("Maximum value is out of bound. (0 < maximum < 1,000,000,000,000,000,000). And your maximum input was [%d]", maximum)
	}

	// Making ID
	// nowUnixNanoTime := strconv.\FormatInt(time.Now().UnixNano(), 10)		// This is Failure. Because of https://stackoverflow.com/questions/55289283/hyperledger-fabric-error-could-not-assemble-transaction-proposalresponsepaylo

	transactionTimestamp, errN := ctx.GetStub().GetTxTimestamp()
	if errN != nil {
		return fmt.Errorf("Failed to get TransactionTimeStamp")
	}
	now := time.Unix(transactionTimestamp.Seconds, int64(transactionTimestamp.Nanos))
	nowString := now.String()
	nowUnixNanoTime := now.UnixNano()

	message := gameName + serverName + characterName + randomBoxName + nowString + strconv.FormatInt(maximum, 10) // Before Hash function
	hash := sha256.New()
	hash.Write([]byte(message))
	digest := hash.Sum(nil)
	id := hex.EncodeToString(digest)

	exists, err := ctx.GetStub().GetState(id)
	if err != nil {
		return err
	}
	if exists != nil {
		return fmt.Errorf("Already exists! %s", message)
	}

	results := GenerateManyRandomInt64WithLimit(nowUnixNanoTime, maximum, howmany)

	randomBox := RandomBox{
		DocType:        "RandomBox",
		ID:             id,
		GameName:       gameName,
		ServerName:     serverName,
		CharacterName:  characterName,
		RandomBoxName:  randomBoxName,
		OpenedUnixTime: nowString,
		Maximum:        maximum,
		Results:        results,
	}

	randomBoxJSON, err := json.Marshal(randomBox)
	if err != nil {
		return err
	}
	return ctx.GetStub().PutState(id, randomBoxJSON)
}

// GetAllRandomBox returns all opened Random Box found in world state
func (s *SmartContract) GetAllRandomBox(ctx contractapi.TransactionContextInterface) ([]*RandomBox, error) {
	resultsIterator, err := ctx.GetStub().GetStateByRange("", "")
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	var openedRandomBoxes []*RandomBox
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var randomBox RandomBox
		err = json.Unmarshal(queryResponse.Value, &randomBox)
		if err != nil {
			return nil, err
		}
		openedRandomBoxes = append(openedRandomBoxes, &randomBox)
	}

	return openedRandomBoxes, nil
}

// constructQueryResponseFromIterator constructs a slice of assets from the resultsIterator
func constructQueryResponseFromIterator(resultsIterator shim.StateQueryIteratorInterface) ([]*RandomBox, error) {
	var randomBoxes []*RandomBox
	for resultsIterator.HasNext() {
		queryResult, err := resultsIterator.Next()
		if err != nil {
			return nil, err
		}
		var randomBox RandomBox
		err = json.Unmarshal(queryResult.Value, &randomBox)
		if err != nil {
			return nil, err
		}
		randomBoxes = append(randomBoxes, &randomBox)
	}

	return randomBoxes, nil
}

func getQueryResultForQueryString(ctx contractapi.TransactionContextInterface, queryString string) ([]*RandomBox, error) {
	resultsIterator, err := ctx.GetStub().GetQueryResult(queryString)
	if err != nil {
		return nil, err
	}
	defer resultsIterator.Close()

	return constructQueryResponseFromIterator(resultsIterator)
}

// QueryAssets uses a query string to perform a query for assets.
func (s *SmartContract) QueryAssets(ctx contractapi.TransactionContextInterface, queryString string) ([]*RandomBox, error) {
	return getQueryResultForQueryString(ctx, queryString)
}

// QueryAssetsByGameName queries for assets based on the owners name.
func (s *SmartContract) QueryAssetsByGameName(ctx contractapi.TransactionContextInterface, gameName string) ([]*RandomBox, error) {
	queryString := fmt.Sprintf(`{"selector":{"DocType":"RandomBox","GameName":"%s"}}`, gameName)
	return getQueryResultForQueryString(ctx, queryString)
}

// QueryAssetsByGameNameAndServerName queries for assets based on the owners name.
func (s *SmartContract) QueryAssetsByGameNameAndServerName(ctx contractapi.TransactionContextInterface, gameName string, serverName string) ([]*RandomBox, error) {
	queryString := fmt.Sprintf(`{"selector":{"DocType":"RandomBox","GameName":"%s","ServerName":"%s"}}`, gameName, serverName)
	return getQueryResultForQueryString(ctx, queryString)
}

// QueryAssetsByGameNameServerNameAndCharacterName queries for assets based on the owners name.
func (s *SmartContract) QueryAssetsByGameNameServerNameAndCharacterName(ctx contractapi.TransactionContextInterface, gameName string, serverName string, characterName string) ([]*RandomBox, error) {
	// '{"Args":["QueryAssets", "{\"selector\":{\"GameName\":\"MapleStory\",\"ServerName\":\"Scania\",\"CharacterName\":\"Hero50322\"}, \"use_index\":[\"defaultDoc\", \"index1\"]}"]}'
	queryString := fmt.Sprintf(`{"selector":{"DocType":"RandomBox","GameName":"%s","ServerName":"%s","CharacterName","%s"}}`, gameName, serverName, characterName)
	return getQueryResultForQueryString(ctx, queryString)
}
