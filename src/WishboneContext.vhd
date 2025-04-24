--
--  File Name:         WishboneContext.vhd
--  Design Unit Name:  WishboneContext
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--
--  Description
--      Context Declaration for using Wishbone models
--
--  Developed by/for:
--        SynthWorks Design Inc.
--        VHDL Training Classes
--        11898 SW 128th Ave.  Tigard, Or  97223
--        http://www.SynthWorks.com
--
--  Revision History:
--    Date      Version    Description
--    04/2025   2025       Initial revision
--
--
--  This file is part of OSVVM.
--  
--  Copyright (c) 2025 by SynthWorks Design Inc.  
--
--  Licensed under the Apache License, Version 2.0 (the "License");
--  you may not use this file except in compliance with the License.
--  You may obtain a copy of the License at
--
--      https://www.apache.org/licenses/LICENSE-2.0
--
--  Unless required by applicable law or agreed to in writing, software
--  distributed under the License is distributed on an "AS IS" BASIS,
--  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
--  See the License for the specific language governing permissions and
--  limitations under the License.
--

context WishboneContext is
    library osvvm_common ;  
    context osvvm_common.OsvvmCommonContext ; -- Address Bus Transactions

    library osvvm_wishbone ;

    use osvvm_wishbone.WishboneInterfacePkg.all ;     -- Interface definition

    use osvvm_wishbone.WishboneOptionsPkg.all ;       -- Model parameters
 --   use osvvm_wishbone.WishboneOptionsArrayPkg.all ;  -- Model parameters - for Array parameters
    use osvvm_wishbone.WishboneModelPkg.all ;         -- Model support

    use osvvm_wishbone.WishboneComponentPkg.all ;     -- Connected Transaction Interface
    
end context WishboneContext ;