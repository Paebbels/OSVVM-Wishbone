--
--  File Name:         WishboneGenericSignalsPkg.vhd
--  Design Unit Name:  WishboneGenericSignalsPkg
--  Revision:          STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--
--  Description
--      Signal Declarations for WISHBONE Interface
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

library ieee ;
  use ieee.std_logic_1164.all ;
  use ieee.numeric_std.all ;

library osvvm ;
    context osvvm.OsvvmContext ;

library osvvm_wishbone ;
    context osvvm_Wishbone.WishboneContext ;
    
package WishboneGenericSignalsPkg is
  generic (
    constant ADDR_WIDTH   : integer := 32 ; 
    constant DATA_WIDTH   : integer := 32 
  ) ; 
  
  constant SEL_WIDTH : integer := DATA_WIDTH/8 ;
  
  signal TransRec  : AddressBusRecType (
          Address      (ADDR_WIDTH-1 downto 0),
          DataToModel  (DATA_WIDTH-1 downto 0),
          DataFromModel(DATA_WIDTH-1 downto 0)
        ) ;

  signal  WishboneBus : WishboneRecType(
    Adr(ADDR_WIDTH-1 downto 0),
    iDat(DATA_WIDTH-1 downto 0),
    oDat(DATA_WIDTH-1 downto 0),
    Sel(SEL_WIDTH-1 downto 0)
  ) ;
  
  -- AXI Write Address Channel
  alias Cyc   is WishboneBus.Cyc   ;
  alias Lock  is WishboneBus.Lock  ;
  alias Stb   is WishboneBus.Stb   ;
  alias We    is WishboneBus.We    ;
  alias Ack   is WishboneBus.Ack   ;
  alias Err   is WishboneBus.Err   ;
  alias Rty   is WishboneBus.Rty   ;
  alias Stall is WishboneBus.Stall ;
  alias Adr   is WishboneBus.Adr   ;
  alias oDat  is WishboneBus.oDat  ;
  alias iDat  is WishboneBus.iDat  ;
  alias Sel   is WishboneBus.Sel   ;
  alias Cti   is WishboneBus.Cti   ;
end package WishboneGenericSignalsPkg ;

