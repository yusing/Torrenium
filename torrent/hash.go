package main

import (
	"github.com/anacrolix/torrent/metainfo"
)

func hexStringToHash(s string) (infoHash metainfo.Hash, err error) {
	err = infoHash.FromHexString(s)
	return infoHash, err
}
