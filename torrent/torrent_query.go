package main

import "C"
import (
	"encoding/json"
	"log"
	"os"
	"unsafe"

	"github.com/anacrolix/torrent"
)

// func FindTorrent(infoHashStr string) (t *torrent.Torrent, infoHash metainfo.Hash) {
// 	if err := infoHash.FromHexString(infoHashStr); err != nil {
// 		return nil, metainfo.Hash{}
// 	}
// 	t, ok := torrentClient.Torrent(infoHash)
// 	if !ok || t == nil {
// 		return nil, infoHash
// 	}
// 	return t, infoHash
// }

//export GetTorrentInfo
func GetTorrentInfo(torrentPtr unsafe.Pointer) *C.char {
	if torrentPtr == nil {
		log.Println("[Torrent-Go] GetTorrentInfo: torrentPtr is nil")
		return jsonify(map[string]interface{}{})
	}
	return jsonify(torrentInfoMap((*torrent.Torrent)(torrentPtr)))
}

func TorrentList() []map[string]interface{} {
	if torrentClient == nil {
		return []map[string]interface{}{}
	}
	var torrents []map[string]interface{}
	for _, t := range torrentClient.Torrents() {
		if t == nil {
			continue
		}
		torrents = append(torrents, torrentInfoMap(t))
	}
	return torrents
}

//export GetTorrentList
func GetTorrentList() *C.char {
	return jsonify(TorrentList())
}

func SaveSession() {
	session, _ := json.Marshal(TorrentList())
	err := os.WriteFile(sessionJsonPath, session, 0644)
	if err != nil {
		log.Printf("Error saving session: %s", err)
	}
}

func LastSessionBytes() []byte {
	// check if sessionJsonPath exists
	if _, err := os.Stat(sessionJsonPath); os.IsNotExist(err) {
		return []byte("[]")
	}
	session, err := os.ReadFile(sessionJsonPath)
	if err != nil {
		log.Printf("Error reading session: %s", err)
		return []byte("[]")
	}
	return session
}

//export GetLastSession
// func GetLastSession() *C.char {
// 	var sessionMap []map[string]interface{}
// 	err := json.Unmarshal(LastSessionBytes(), &sessionMap)
// 	if err != nil {
// 		return jsonify([]map[string]interface{}{})
// 	}
// 	return jsonify(sessionMap)
// }
