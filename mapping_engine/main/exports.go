// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main
/*
#include "mapping.h"
*/
import "C"
import (
	"context"
	"log"

	"github.com/GoogleCloudPlatform/healthcare-data-harmonization/mapping_engine/transform" /* copybara-comment: transform */
	"google.golang.org/protobuf/encoding/prototext"                                         /* copybara-comment: prototext */

	dhpb "github.com/GoogleCloudPlatform/healthcare-data-harmonization/mapping_engine/proto"             /* copybara-comment: data_harmonization_go_proto */ /* copybara-comment: harmonization_go_proto */ /* copybara-comment: http_go_proto */ /* copybara-comment: library_go_proto */
	fileutil "github.com/GoogleCloudPlatform/healthcare-data-harmonization/mapping_engine/util/ioutil"   /* copybara-comment: ioutil */
	jsonutil "github.com/GoogleCloudPlatform/healthcare-data-harmonization/mapping_engine/util/jsonutil" /* copybara-comment: jsonutil */
)

// RunMapping converts JSON string of one structure to another, based on the
// configuration file dhConfigFile. It is an export function to use in C.
//export RunMapping
func RunMapping(input string, dhConfigFile string) *C.MappingResult {
	dhConfig := &dhpb.DataHarmonizationConfig{}

	n := fileutil.MustRead(dhConfigFile, "data harmonization config")
	if err := prototext.Unmarshal(n, dhConfig); err != nil {
		log.Fatalf("Go: Failed to parse data harmonization config")
	}

	tconfig := transform.TransformationConfig{}

	var tr transform.Transformer
	var err error

	result := (*C.MappingResult)(C.malloc(C.sizeof_MappingResult))
    result.result = nil
    result.error = nil

	if tr, err = transform.NewTransformer(context.Background(), dhConfig, tconfig); err != nil {
		// log.Fatalf("Go: Failed to load mapping config: %v", err)
		result.error = C.CString(err.Error())
		return result
	}

	i := []byte(input)
	ji, err := tr.ParseJSON(i)
	if err != nil {
		// log.Fatalf("Go: Failed to parse input JSON")
		result.error = C.CString(err.Error())
		return result
	}

	res, err := tr.Transform(ji)
	if err != nil {
		// log.Fatalf("Go: Mapping failed!!!")
		result.error = C.CString(err.Error())
		return result
	}

	resstr := jsonutil.MarshalJSON(res)
	result.result = C.CString(resstr)

	return result
}
