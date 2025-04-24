--
--  File Name:         WishboneInterfacePkg.vhd
--  Design Unit Name:  WishboneInterfacePkg
--  Revision:          OSVVM MODELS STANDARD VERSION
--
--  Maintainer:        Jim Lewis      email:  jim@synthworks.com
--  Contributor(s):
--     Jim Lewis      jim@synthworks.com
--
--
--  Description:
--      Defines types, constants, and subprograms to support the Axi4 interface to DUT
--      These are currently only intended for testbench models.
--      When VHDL-2018 intefaces gain popular support, these will be changed to support them. 
--          
--
--  Developed by:
--        SynthWorks Design Inc.
--        VHDL Training Classes
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
  use ieee.numeric_std_unsigned.all ;
  
  
package WishboneInterfacePkg is 
  
  type WishboneRecType is record
    Cyc       : std_logic ; 
    Lock      : std_logic ; 
    Stb       : std_logic ; 
    We        : std_logic ; 
    Ack       : std_logic ; 
    Err       : std_logic ; 
    Rty       : std_logic ; 
    Stall     : std_logic ; 
    Adr       : std_logic_vector ; 
    oDat      : std_logic_vector ; 
    iDat      : std_logic_vector ; 
    Sel       : std_logic_vector ; 
    Cti       : std_logic_vector(2 downto 0) ;
  end record WishboneRecType ; 
  
  type WishboneRecArrayType  is array (integer range <>) of WishboneRecType ;

--
-- Add VHDL-2019 mode views here
--

  
  function InitWishboneRec (
    WishboneBusRec : in WishboneRecType ;
    InitVal        : std_logic := 'Z'
  ) return WishboneRecType ;
  
  procedure InitWishboneRec (
    signal WishboneBusRec : inout WishboneRecType ;
    InitVal               : std_logic := 'Z'
  ) ;
  
end package WishboneInterfacePkg ;
package body WishboneInterfacePkg is 

  function InitWishboneRec (
    WishboneBusRec : in WishboneRecType ;
    InitVal        : std_logic := 'Z'
  ) return WishboneRecType is
  begin
    return (
      Cyc       => InitVal,
      Lock      => InitVal,
      Stb       => InitVal,
      We        => InitVal,
      Ack       => InitVal,
      Err       => InitVal,
      Rty       => InitVal,
      Stall     => InitVal,
      
      Adr       => (WishboneBusRec.Adr'range => InitVal),
      oDat      => (WishboneBusRec.oDat'range => InitVal),
      iDat      => (WishboneBusRec.iDat'range => InitVal),
      Sel       => (WishboneBusRec.Sel'range => InitVal),
      Cti       => (WishboneBusRec.Cti'range => InitVal)
    ) ;
  end function InitWishboneRec ; 

  procedure InitWishboneRec (
    signal WishboneBusRec : inout WishboneRecType ;
    InitVal               : std_logic := 'Z'
  ) is
  begin
    WishboneBusRec <= InitWishboneRec(WishboneBusRec, InitVal) ;
  end procedure InitWishboneRec ;

end package body WishboneInterfacePkg ; 

  

