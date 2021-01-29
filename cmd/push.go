/*
Copyright © 2021 NAME HERE <EMAIL ADDRESS>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/
package cmd

import (
	"bytes"
	"crossshare-cli/utils"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"os"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	RemoteURL = "http://localhost:6020"
	PUSH      = "/api/v1/push"
	PULL      = "/api/v1/pull"
)

// pushCmd represents the push command
var pushCmd = &cobra.Command{
	Use:   "push",
	Short: "push text or file to remote server for pull",
	Long: `You can use push to push text to remote server, when you need it,then pull it.
	And you can push file to remote server, then pull it when needed.`,
	Aliases: []string{"set"},
	Run: func(cmd *cobra.Command, args []string) {
		push(cmd)
	},
}

func init() {
	rootCmd.AddCommand(pushCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// pushCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// pushCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	pushCmd.Flags().StringP("input", "i", "", "input file")
	// TODO ttl flag to specify ttl (works only less than server ttl)
	// viper.BindPFlag("input", pushCmd.Flags().Lookup("input"))
}

func push(cmd *cobra.Command) {
	verbose := viper.GetBool("verbose")
	inputFile := cmd.Flags().Lookup("input").Value.String()
	if viper.GetString("remote_url") != "" {
		RemoteURL = viper.GetString(("remote_url"))
	}
	if verbose {
		logrus.Infof("Remote url: %s", RemoteURL)
	}
	var (
		rd  io.Reader
		err error
	)

	if len(inputFile) > 0 {
		if verbose {
			logrus.Infof("read from file: %v", inputFile)
		}
		rd, err = os.Open(inputFile)
		if err != nil {
			utils.QuitMsg(fmt.Sprintf("Open input file error: %v", err))
		}
	} else {
		if verbose {
			logrus.Infof("read from stdin")
		}
		rd = os.Stdin
		fmt.Fprintf(os.Stderr, "> ")
	}
	result, err := ioutil.ReadAll(rd)
	if err != nil {
		utils.QuitMsg(fmt.Sprintf("read input error: %v", err))
	}

	req, err := http.NewRequest("POST", RemoteURL+PUSH, bytes.NewBuffer(result))
	if len(inputFile) > 0 {
		if verbose {
			logrus.Infof("set request header Filename: %v", inputFile)
		}
		req.Header.Set("Filename", inputFile)
	}
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		utils.QuitMsg(fmt.Sprintf("POST error: %v", err))
	}
	defer resp.Body.Close()
	io.Copy(os.Stdout, resp.Body)
}
