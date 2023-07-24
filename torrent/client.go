package main

import "C"
import (
	"encoding/json"
	"log"
	"os"
	"path"

	"github.com/anacrolix/torrent"
)

var torrentClient *torrent.Client = nil
var savePath string
var dataPath string
var sessionJsonPath string

func loadLastSession() {
	sessionRaw := LastSessionBytes()

	var session []map[string]interface{}
	err := json.Unmarshal(sessionRaw, &session)
	if err != nil {
		log.Printf("Error parsing session: %s", err)
		return
	}
	for _, torrentInfoMap := range session {
		ReadMetadataAndAdd(torrentInfoMap["info_hash"].(string))
	}
	log.Println("Session loaded")
}

//export InitTorrentClient
func InitTorrentClient(savePathCStr *C.char) {
	if torrentClient != nil {
		return // Already initialized, maybe flutter hot reload?
	}
	savePath = C.GoString(savePathCStr)
	dataPath = path.Join(savePath, "data")
	os.MkdirAll(dataPath, 0755)
	sessionJsonPath = path.Join(dataPath, "session.json")
	config := torrent.NewDefaultClientConfig()
	config.NoDHT = false
	config.NoUpload = true
	config.DataDir = dataPath
	config.Seed = false
	config.DisableIPv6 = true
	torrentClient, _ = torrent.NewClient(config)
	loadLastSession()
}

func main() {}
