// Copyright 2022 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// Author:      Florian Zaruba <zarubaf@iis.ee.ethz.ch>
//              Andreas Kuster, <kustera@ethz.ch>
// Description: Minimal AXI configuration (adapted from openhwgroup:cva6 ariane_axi_soc_pkg.sv)

package axi_conf;

    typedef enum logic [1:0] {
        RESP_OKAY   = 2'b00, // normal access success
        RESP_EXOKAY = 2'b01, // exclusive access okay
        RESP_SLVERR = 2'b10, // slave error
        RESP_DECERR = 2'b11  // decode error
        } axi_trans_resp_t;

endpackage
