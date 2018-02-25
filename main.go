package main

import (
	"log"
	"os"
	"os/exec"
	"strconv"
	"strings"
)

func main() {
	if len(os.Args) < 2 {
		log.Fatal("Usage: macOSvm path/to/Install\\ macOS.app")
	}

	if !isVboxInstalled() {
		log.Fatal("Please install VirtualBox.")
	}

	log.Println("Ready to install macOS")

}

func isVboxInstalled() bool {
	err := exec.Command("which", "VBoxManage2").Run()
	return err == nil
}

func cpuCoreCount() int {
	cpuInfo, err := exec.Command("sysctl", "hw.memsize").CombinedOutput
	if err != nil {
		log.Fatal("Something went wrong while reading ncpu from sysctl")
	}

	return strconv.Atoi(strings.Fields(cpuInfo)[1])
}

func ramGbCount() int {
	ramInfo, err := exec.Command("sysctl", "hw.memsize").CombinedOutput
	if err != nil {
		log.Fatal("Something went wrong while reading memsize from sysctl")
	}

	return strconv.Atoi(strings.Fields(ramInfo)[1])
}
