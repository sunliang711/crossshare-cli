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
	"crossShareClient/types"
	"crossShareClient/utils"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	RemoteURL = "http://localhost:6020"
	PUSH_TEXT = "/api/v1/push_text"
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
	if len(inputFile) > 0 {
		fmt.Fprintf(os.Stderr, "%s\n", "TODO")
		os.Exit(1)
	} else {
		// read stdin
		var result []byte
		buf := make([]byte, 1024)
		if verbose {
			logrus.Infof("Read from stdin...\n")
		}
		for {
			n, err := os.Stdin.Read(buf)
			if n > 0 {
				result = append(result, buf[:n]...)
			}
			if err == io.EOF {
				if verbose {
					logrus.Infof("End\n")
				}
				break
			} else if err != nil {
				utils.QuitMsg(fmt.Sprintf("read stdin error: %v", err))
			}
		}

		data := types.Share{Content: string(result)}
		bs, err := json.Marshal(&data)
		if err != nil {
			utils.QuitMsg(fmt.Sprintf("Encode request body error: %v", err))
		}

		req, err := http.NewRequest("POST", RemoteURL+PUSH_TEXT, bytes.NewBuffer(bs))
		req.Header.Set("Content-Type", "application/json")
		client := &http.Client{}
		resp, err := client.Do(req)
		if err != nil {
			utils.QuitMsg(fmt.Sprintf("POST error: %v", err))
		}
		defer resp.Body.Close()
		io.Copy(os.Stdout, resp.Body)
	}
}
