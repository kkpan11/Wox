package util

import (
	"github.com/samber/lo"
	"os"
	"path/filepath"
	"strconv"
	"strings"
)

// IsFileExecAny returns true if the file mode indicates that the file is executable by any user.
func IsFileExecAny(mode os.FileMode) bool {
	return mode&0111 != 0
}

func IsFileExists(path string) bool {
	stat, err := os.Stat(path)
	return err == nil && !stat.IsDir()
}

func IsDirExists(path string) bool {
	stat, err := os.Stat(path)
	return err == nil && stat.IsDir()
}

func ListDir(path string) ([]string, error) {
	dir, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}

	var files []string
	for _, file := range dir {
		files = append(files, file.Name())
	}

	return files, nil
}

func IsImageFile(path string) bool {
	currentExt := strings.ToLower(filepath.Ext(path))
	imageSuffixList := []string{".png", ".jpg", ".jpeg", ".gif", ".bmp", ".webp", ".tiff", ".svg"}
	return lo.Contains(imageSuffixList, currentExt)
}

func GetFileModifiedAt(path string) string {
	stat, err := os.Stat(path)
	if err != nil {
		return "-"
	}

	return FormatTime(stat.ModTime())
}

func GetFileSize(path string) string {
	stat, err := os.Stat(path)
	if err != nil {
		return "-"
	}

	//if size is less than 1KB, show bytes
	//if size is less than 1MB, show KB
	//if size is less than 1GB, show MB
	//if size is less than 1TB, show GB
	//if size is less than 1PB, show TB

	size := stat.Size()
	if size < 1024 {
		return strconv.FormatInt(size, 10) + " B"
	}
	if size < 1024*1024 {
		return strconv.FormatInt(size/1024, 10) + " KB"
	}
	if size < 1024*1024*1024 {
		return strconv.FormatInt(size/1024/1024, 10) + " MB"
	}
	if size < 1024*1024*1024*1024 {
		return strconv.FormatInt(size/1024/1024/1024, 10) + " GB"
	}
	if size < 1024*1024*1024*1024*1024 {
		return strconv.FormatInt(size/1024/1024/1024/1024, 10) + " TB"
	}

	return "-"
}
