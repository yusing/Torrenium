package main

import "C"
import (
	"encoding/json"
	"unsafe"

	"github.com/anacrolix/torrent"
)

func jsonify[M interface{}](mapLike M) *C.char {
	j, err := json.Marshal(mapLike)
	if err != nil {
		return nil
	}
	return C.CString(string(j))
}

func torrentFileMap(f []*torrent.File) []map[string]interface{} {
	if f == nil {
		return []map[string]interface{}{}
	}
	var files []map[string]interface{}
	for _, file := range f {
		files = append(files, map[string]interface{}{
			"name":             file.DisplayPath(),
			"size":             file.Length(),
			"rel_path":         file.Path(),
			"bytes_downloaded": file.BytesCompleted(),
			"progress":         float64(file.BytesCompleted()) / float64(file.Length()),
		})
	}
	return files
}

func torrentInfoMap(t *torrent.Torrent) map[string]interface{} {
	if t == nil {
		return nil
	}

	return map[string]interface{}{
		"name":             t.Name(),
		"info_hash":        t.InfoHash().String(),
		"size":             t.Length(),
		"bytes_downloaded": t.BytesCompleted(),
		"progress":         float64(t.BytesCompleted()) / float64(t.Length()),
		"files":            torrentFileMap(t.Files()),
		"ptr":              uintptr(unsafe.Pointer(t)),
	}
}
