# Copyright 2020 The Magma Authors.

# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
SHELL := /bin/bash
.PHONY: build clean clean_gen download fmt gen lint plugin test tidy vet migration_plugin

build:: plugin
	go install ./...

clean::
	go clean ./...

clean_gen:
	for f in $$(find . -name '*.pb.go' ! -path '*/migrations/*') ; do rm $$f ; done
	for f in $$(find . -name '*_swaggergen.go' ! -path '*/migrations/*') ; do rm $$f ; done

download:
	go mod download

fmt::
	go fmt ./...

gen::
	go generate ./...


# swagger.v1.yml files are expected to be arranged one-per-service, at the
# following location
#
#	MODULE/cloud/go/services/SERVICE/obsidian/models/swagger.v1.yml
#
# copy_swagger_files copies Swagger files to the tmp directory under the name
#
#	MODULE.SERVICE.swagger.v1.yml
#
# For example
#	- Before: lte/cloud/go/services/policydb/obsidian/models/swagger.v1.yml
#	- After: TMP_GEN/lte.policydb.swagger.v1.yml
copy_swagger_files:
	for f in $$(find . -name swagger.v1.yml) ; do cp $$f $${SWAGGER_V1_TMP_GEN}/$(MODULE_NAME).$$(echo $$f | sed -r 's/.*\/services\/([^\/]*)\/obsidian\/models\/(swagger\.v1\.yml)/\1.\2/g') ; done

lint:
	golint ./...

plugin::
	go build -buildmode=plugin -o $(PLUGIN_DIR)/$(PLUGIN_NAME).so .

test::
	go test ./...

tidy:
	go mod tidy

tools:: $(TOOL_DEPS)
$(TOOL_DEPS): %:
	go install $*

vet::
	go vet -composites=false ./...

COVER_FILE=$(COVER_DIR)/$(PLUGIN_NAME).gocov
cover:
	go test ./... -coverprofile $(COVER_FILE);
	# Don't measure coverage for protos and tools
	sed -i '/\.pb\.go/d; /.*\/tools\/.*/d; /.*_swaggergen\.go/d' $(COVER_FILE);
	go tool cover -func=$(COVER_FILE)


# for configurator data migration
migration_plugin:
	if [[ -d ./tools/migrations/m003_configurator/plugin ]]; then \
		go build -buildmode=plugin -o $(PLUGIN_DIR)/migrations/m003_configurator/$(PLUGIN_NAME).so ./tools/migrations/m003_configurator/plugin; \
	fi
