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
	"crossshare-cli/types"
	"crossshare-cli/utils"
	"encoding/json"
	"fmt"
	"net/http"
	"os"

	"github.com/sirupsen/logrus"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

// pullCmd represents the pull command
var pullCmd = &cobra.Command{
	Use:   "pull",
	Short: "pull text or file from remote",
	Long: `pull command can pull text from remote server(output to stdout), use -o flag to save it as file.
	pull command can pull file from remote server saved as it's original name when it pushed`,
	Aliases: []string{"get"},
	Run: func(cmd *cobra.Command, args []string) {
		pull(cmd)
	},
}

func init() {
	rootCmd.AddCommand(pullCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// pullCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// pullCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	pullCmd.Flags().StringP("output", "o", "", "output file")
	// viper.BindPFlag("output", pullCmd.Flags().Lookup("output"))
	pullCmd.Flags().BoolP("tcp", "t", false, "tcp")
}

func pull(cmd *cobra.Command) {
	if cmd.Flags().NArg() < 1 {
		fmt.Fprintf(os.Stderr, "Pull need key\n")
		os.Exit(1)
	}
	key := cmd.Flags().Arg(0)
	outputFile := cmd.Flag("output").Value.String()
	verbose := viper.GetBool("verbose")
	if verbose {
		logrus.Infof("Key: %v", key)
		logrus.Infof("Output file: %v", outputFile)
	}

	if viper.GetString("remote_url") != "" {
		RemoteURL = viper.GetString(("remote_url"))
	}
	if verbose {
		logrus.Infof("Remote url: %s", RemoteURL)
	}

	resp, err := http.Get(fmt.Sprintf("%s%s/%s", RemoteURL, PULL, key))
	if err != nil {
		panic(err)
	}
	defer resp.Body.Close()
	// io.Copy(os.Stdout, resp.Body)

	var r types.Share
	if err := json.NewDecoder(resp.Body).Decode(&r); err != nil {
		utils.QuitMsg(fmt.Sprintf("Decode response error: %v\n", err))
	}
	if r.Code != types.OK {
		utils.QuitMsg(fmt.Sprintf("Error: %s\n", r.Msg))
	}

	switch r.Type {
	case types.TextType:
		if len(outputFile) > 0 {
			if f, err := os.OpenFile(outputFile, os.O_TRUNC|os.O_CREATE|os.O_WRONLY, 0600); err != nil {
				utils.QuitMsg(fmt.Sprintf("Open file error: %v", err))
			} else {
				fmt.Fprintf(f, "%s", r.Content)
			}
		} else {
			fmt.Fprintf(os.Stdout, "%s", r.Content)
		}
	case types.FileType:
		utils.QuitMsg("FileType TODO\n")
	default:
		utils.QuitMsg("Invalid type\n")
	}

}
