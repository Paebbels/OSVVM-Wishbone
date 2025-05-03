#  File Name:         Axi4.pro
#  Revision:          STANDARD VERSION
#
#  Maintainer:        Jim Lewis      email:  jim@synthworks.com
#  Contributor(s):
#     Jim Lewis      jim@synthworks.com
#
#
#  Description:
#        Script to compile the Axi4 models  
#
#  Developed for:
#        SynthWorks Design Inc.
#        VHDL Training Classes
#        11898 SW 128th Ave.  Tigard, Or  97223
#        http://www.SynthWorks.com
#
#  Revision History:
#    Date      Version    Description
#    04/2025   2025       Initial revision
#
#
#  This file is part of OSVVM.
#  
#  Copyright (c) 2025 by SynthWorks Design Inc.  
#  
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#  
#      https://www.apache.org/licenses/LICENSE-2.0
#  
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
library osvvm_wishbone
ChangeWorkingDirectory src

analyze WishboneInterfacePkg.vhd
analyze WishboneOptionsPkg.vhd
analyze WishboneModelPkg.vhd
analyze WishboneManager.vhd
analyze WishboneRegisterSubordinate.vhd
analyze WishbonePassThru.vhd
analyze WishboneComponentPkg.vhd
analyze WishboneContext.vhd
analyze WishboneGenericSignalsPkg.vhd
