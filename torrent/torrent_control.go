package main

import "C"
import (
	"encoding/json"
	"io"
	"log"
	"net/http"
	"os"
	"path"
	"unsafe"

	"github.com/anacrolix/torrent"
	"github.com/anacrolix/torrent/metainfo"
)

func AddTorrentFromInfoHash(infoHashStr string) *torrent.Torrent {
	infoHash := torrent.InfoHash{}
	if parseErr := infoHash.FromHexString(infoHashStr); parseErr != nil {
		log.Printf("[Torrent-Go] Error parsing infoHash: %s %s", infoHashStr, parseErr)
		return nil
	} else {
		t, ok := torrentClient.AddTorrentInfoHash(infoHash)
		if t == nil || !ok {
			log.Printf("[Torrent-Go] Error adding torrent from infoHash %s", infoHashStr)
		}
		<-t.GotInfo()
		t.DownloadAll()
		SaveMetadata(t)
		return t
	}
}

func SaveMetadata(t *torrent.Torrent) {
	metaInfoJson, err := json.Marshal(t.Metainfo())
	if err != nil {
		log.Printf("[Torrent-Go] Error saving metadata: %s", err)
		return
	}
	err = os.WriteFile(path.Join(dataPath, t.InfoHash().HexString()+".json"), metaInfoJson, 0644)
	if err != nil {
		log.Printf("[Torrent-Go] Error saving metadata: %s", err)
	}
}

func ReadMetadataAndAdd(infoHashStr string) *torrent.Torrent {
	// fallback to AddTorrentFromInfoHash if metadata not found
	metaInfoJsonBytes, err := os.ReadFile(path.Join(dataPath, infoHashStr+".json"))
	if err != nil {
		log.Printf("[Torrent-Go] Error reading metadata: %s", err)
		AddTorrentFromInfoHash(infoHashStr)
		return nil
	}
	metaInfo := metainfo.MetaInfo{}
	if metaInfoParseErr := json.Unmarshal(metaInfoJsonBytes, &metaInfo); metaInfoParseErr != nil {
		log.Printf("[Torrent-Go] Error parsing metaInfo: %s", metaInfoParseErr)
		return AddTorrentFromInfoHash(infoHashStr)
	} else {
		t, _ := torrentClient.AddTorrent(&metaInfo)
		<-t.GotInfo()
		t.DownloadAll()
		return t
	}
}

//export AddMagnet
func AddMagnet(magnetCString *C.char) *C.char {
	magnet := C.GoString(magnetCString)
	log.Printf("Adding torrent: %s", magnet)
	t, err := torrentClient.AddMagnet(magnet)
	if t == nil || err != nil {
		return jsonify([]map[string]interface{}{})
	}
	<-t.GotInfo()
	log.Printf("Added %p", t)
	t.DownloadAll()
	SaveMetadata(t)
	SaveSession()
	torrentInfoMap := torrentInfoMap(t)
	return jsonify(torrentInfoMap)
}

//export AddTorrent
func AddTorrent(torrentUrlCStr *C.char) *C.char {
	torrentUrl := C.GoString(torrentUrlCStr)
	torrentPath := path.Join(dataPath, path.Base(torrentUrl))
	torrentFile, err := os.Create(torrentPath)
	if err != nil {
		log.Printf("[Torrent-Go] Error creating torrent file: %s", err)
		return jsonify([]map[string]interface{}{})
	}
	defer torrentFile.Close()
	resp, err := http.Get(torrentUrl)
	if err != nil {
		log.Printf("[Torrent-Go] Error downloading torrent file: %s", err)
		return jsonify([]map[string]interface{}{})
	}
	defer resp.Body.Close()
	_, err = io.Copy(torrentFile, resp.Body)
	if err != nil {
		log.Printf("[Torrent-Go] Error reading torrent file: %s", err)
		return jsonify([]map[string]interface{}{})
	}
	t, err := torrentClient.AddTorrentFromFile(torrentPath)
	os.Remove(torrentPath)
	if t == nil || err != nil {
		log.Printf("[Torrent-Go] Error adding torrent: %s", err)
		return jsonify([]map[string]interface{}{})
	}
	<-t.GotInfo()
	torrentInfoMap := torrentInfoMap(t)
	t.DownloadAll()
	SaveMetadata(t)
	SaveSession()
	return jsonify(torrentInfoMap)
}

//export PauseTorrent
func PauseTorrent(torrentPtr unsafe.Pointer) {
	if torrentPtr == nil {
		return
	}
	t := (*torrent.Torrent)(torrentPtr)
	SaveMetadata(t)
	t.Drop()
}

//export ResumeTorrent
func ResumeTorrent(infoHashCStr *C.char) uintptr {
	t := ReadMetadataAndAdd(C.GoString(infoHashCStr))
	return uintptr(unsafe.Pointer(t))
}

//export DeleteTorrent
func DeleteTorrent(torrentPtr unsafe.Pointer) {
	if torrentPtr == nil {
		return
	}
	t := (*torrent.Torrent)(torrentPtr)
	// remove files/directory
	infoHashStr := t.InfoHash().HexString()
	t.Drop()
	var err error
	if t.Info().IsDir() {
		err = os.RemoveAll(path.Join(savePath, t.Name()))
	} else {
		err = os.Remove(path.Join(savePath, t.Name()))
	}
	if err != nil {
		log.Printf("[Torrent-Go] Warning: Error deleting files: %s", err)
	}
	if (os.Remove(path.Join(dataPath, infoHashStr+".json"))) != nil {
		log.Printf("[Torrent-Go] Warning: Error deleting metadata: %s", err)
	}
	SaveSession()
}
